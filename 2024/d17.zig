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

const Buffer = myf.FixedBuffer(u8, 16);
const Programs = std.ArrayList(OpCode);

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

fn fakeAssembly(a_value: u64, program: []const OpCode) !Buffer {
    const A = 0;
    const B = 1;
    const C = 2;

    var registers = myf.FixedBuffer(u64, 3).initDefaultValue(0);
    try registers.set(A, a_value);

    var buf = Buffer.init();
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

fn part1(a_value: u64, program: []const OpCode) !myf.FixedBuffer(u8, 20) {
    var buf = try fakeAssembly(a_value, program);
    var output = myf.FixedBuffer(u8, 20).init();

    for (buf.getSlice(), 0..) |v, i| {
        try output.append(v + '0');
        if (buf.len - 1 != i) try output.append(',');
    }
    return output;
}

fn part2(number: u64, level: u8, max_level: u8, expected: []const u8, program: []const OpCode) !u64 {
    if (level == max_level) return number / 8;

    var min_value: u64 = 1 << 63;
    for (number..number + 8) |value| {
        var res = try assembly(value);
        if (std.mem.eql(u8, res.getSlice(), expected[max_level - level - 1 ..])) {
            const result = try part2(value * 8, level + 1, max_level, expected, program);
            if (result < min_value) min_value = result;
        }
    }
    return min_value;
}

fn assembly(a_value: u64) !Buffer {
    var a = a_value;
    var buf = Buffer.init();

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

fn part2_alt(number: u64, level: u8, max_level: u8, expected: []const u8) !u64 {
    if (level == max_level) return number / 8;

    var min_value: u64 = 1 << 63;
    for (number..number + 8) |value| {
        var res = try assembly(value);
        if (std.mem.eql(u8, res.getSlice(), expected[max_level - level - 1 ..])) {
            const result = try part2_alt(value * 8, level + 1, max_level, expected);
            if (result < min_value) min_value = result;
        }
    }
    return min_value;
}

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [700]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

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

    var res = try part1(register_A_value, program.items);
    try writer.print("Part 1: {s}\nPart 2: {d}\n", .{
        res.getSlice(),
        try part2(1, 0, 16, expect_buf, program.items), // try rec(1, 0, 16, expect_buf)
    });
}
