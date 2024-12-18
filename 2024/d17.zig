const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const OpCode = enum(u3) {
    adv = 0,
    bxl = 1,
    bst = 2,
    jnz = 3,
    bxc = 4,
    out = 5,
    bdv = 6,
    cdv = 7,
};

const Programs = std.ArrayList(OpCode);

fn eqBuffers(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |ea, eb| if (ea != eb) return false;
    return true;
}

fn assembly(a_value: u64) !myf.FixedBuffer(u8, 16) {
    var a = a_value;
    var buf = myf.FixedBuffer(u8, 16).init();

    while (a != 0) {
        var b = a & 7;
        b ^= 1;
        b ^= @divTrunc(a, std.math.powi(u64, 2, b) catch unreachable);
        b ^= 4;
        a = @divTrunc(a, 8);
        try buf.append(@truncate(b & 7));
    }
    return buf;
}

fn rec(number: u64, level: u8, max_level: u8, expected: []const u8) !u64 {
    if (level == max_level) return number / 8;

    var min_value: u64 = 1 << 63;
    for (number..number + 8) |value| {
        var res = try assembly(value);
        if (eqBuffers(res.getSlice(), expected[max_level - level - 1 ..])) {
            const result = try rec(value * 8, level + 1, max_level, expected);
            if (result < min_value) min_value = result;
        }
    }
    return min_value;
}

fn fakeAssembly(a_value: u64, program: []const OpCode) !myf.FixedBuffer(u8, 16) {
    const A = 0;
    const B = 1;
    const C = 2;

    var registers = myf.FixedBuffer(u64, 3).initDefaultValue(0);
    try registers.set(A, a_value);

    var buf = myf.FixedBuffer(u8, 16).init();
    var pc: u64 = 0;

    while (true) {
        if (pc >= program.len) break;

        const op = program[pc];
        pc += 1;
        const combo = program[pc];
        pc += 1;

        switch (op) {
            .adv => try registers.set(A, @divTrunc(
                try registers.get(A),
                try std.math.powi(u64, 2, (try getComboVal(registers, combo)).?),
            )),
            .bxl => try registers.set(B, try registers.get(B) ^ @intFromEnum(combo)),
            .bst => try registers.set(B, (try getComboVal(registers, combo)).? & 7),
            .jnz => {
                if (try registers.get(A) != 0) pc = @intFromEnum(combo);
            },
            .bxc => try registers.set(B, try registers.get(B) ^ try registers.get(C)),
            .out => try buf.append(@truncate((try getComboVal(registers, combo)).? & 7)),
            .bdv => try registers.set(B, @divTrunc(
                try registers.get(A),
                try std.math.powi(u64, 2, (try getComboVal(registers, combo)).?),
            )),
            .cdv => try registers.set(C, @divTrunc(
                try registers.get(A),
                try std.math.powi(u64, 2, (try getComboVal(registers, combo)).?),
            )),
        }
    }
    return buf;
}

fn genOutput(allocator: Allocator, slice: []const u8) ![]u8 {
    var output = std.ArrayList(u8).init(allocator);
    defer output.deinit();

    for (slice, 0..) |v, i| {
        try output.append(v + '0');
        if (slice.len - 1 != i) try output.append(',');
    }
    return output.toOwnedSlice();
}

fn getComboVal(registers: myf.FixedBuffer(u64, 3), combo: OpCode) !?u64 {
    var reg = registers;
    return switch (@intFromEnum(combo)) {
        0...3 => |v| v,
        4 => try reg.get(0),
        5 => try reg.get(1),
        6 => try reg.get(2),
        else => null,
    };
}

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var in_iter = std.mem.tokenizeSequence(u8, input, double_delim);

    const raw_registers = in_iter.next().?;
    const raw_program = in_iter.next().?;

    var program = Programs.init(allocator);
    defer program.deinit();

    var register_A_value: u64 = 0;

    var raw_register_iter = std.mem.tokenizeSequence(u8, raw_registers, input_attributes.delim);
    if (raw_register_iter.next()) |reg| {
        const last_idx = std.mem.lastIndexOfScalar(u8, reg, ' ').? + 1;
        register_A_value = try std.fmt.parseInt(u64, reg[last_idx..], 10);
    }

    const p_idx = std.mem.indexOfScalar(u8, raw_program, ' ').? + 1;
    var raw_program_iter = std.mem.tokenizeScalar(u8, raw_program[p_idx..], ',');
    while (raw_program_iter.next()) |prog| {
        const op: OpCode = @enumFromInt(std.mem.trim(u8, prog, "\r\n")[0] - '0');
        try program.append(op);
    }

    var expect_buf: []u8 = try allocator.alloc(u8, program.items.len);
    defer allocator.free(expect_buf);

    for (program.items, 0..) |op, i| expect_buf[i] = @intFromEnum(op);

    var part1_raw_res = try fakeAssembly(register_A_value, program.items);

    const p1_res = try genOutput(allocator, part1_raw_res.getSlice());
    defer allocator.free(p1_res);

    try writer.print("Part 1: {s}\nPart 2: {d}\n", .{
        p1_res,
        try rec(1, 0, 16, expect_buf),
    });
}
