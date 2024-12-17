const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

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

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    const input = @embedFile("in/d17.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var in_iter = std.mem.tokenizeSequence(u8, input, double_delim);

    const raw_registers = in_iter.next().?;
    const raw_program = in_iter.next().?;

    var registers = Registers.init(allocator);
    defer registers.deinit();
    var programs = Programs.init(allocator);
    defer programs.deinit();

    var raw_register_iter = std.mem.tokenizeSequence(u8, raw_registers, input_attributes.delim);
    while (raw_register_iter.next()) |reg| {
        const idx = std.mem.indexOfScalar(u8, reg, ' ').? + 1;
        const last_idx = std.mem.lastIndexOfScalar(u8, reg, ' ').? + 1;
        try registers.put(reg[idx], try std.fmt.parseInt(u64, reg[last_idx..], 10));
    }

    const p_idx = std.mem.indexOfScalar(u8, raw_program, ' ').? + 1;
    var raw_program_iter = std.mem.tokenizeScalar(u8, raw_program[p_idx..], ',');
    while (raw_program_iter.next()) |prog| {
        const op: OpCode = @enumFromInt(std.mem.trim(u8, prog, "\r\n")[0] - '0');
        try programs.append(op);
    }

    // try part1(allocator, try registers.clone(), programs.items);
    for (117400..1_000_000_000) |i| {
        registers.putAssumeCapacity(A, i);
        if (try part2(allocator, try registers.clone(), programs.items)) |res| {
            printa(res);
            break;
        }
    }
}

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

const A = 'A';
const B = 'B';
const C = 'C';

const Registers = std.AutoArrayHashMap(u8, u64);
const Programs = std.ArrayList(OpCode);

fn getComboVal(registers: Registers, combo: OpCode) ?u64 {
    return switch (OpTou64(combo)) {
        0...3 => |v| v,
        4 => registers.get(A).?,
        5 => registers.get(B).?,
        6 => registers.get(C).?,
        else => null,
    };
}

fn eqBuffers(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |ea, eb| if (ea != eb) return false;
    return true;
}

fn OpTou64(op: OpCode) u64 {
    return @intCast(@intFromEnum(op));
}

fn part2(allocator: Allocator, registers_: Registers, programs: []const OpCode) !?u64 {
    var registers = registers_;
    defer registers.deinit();

    const A_init_val = registers.get(A).?;
    var expect_buf: []u8 = try allocator.alloc(u8, programs.len);
    for (programs, 0..) |op, i| {
        expect_buf[i] = @intFromEnum(op);
    }
    defer allocator.free(expect_buf);

    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    var pc: u64 = 0;

    while (true) {
        if (pc >= programs.len) break;

        const op = programs[pc];
        pc += 1;
        const combo = programs[pc];
        pc += 1;

        switch (op) {
            .adv => {
                const num = registers.get(A).?;
                const den = try std.math.powi(u64, 2, getComboVal(registers, combo).?);
                registers.putAssumeCapacity(A, @divTrunc(num, den));
            },
            .bxl => {
                const result = registers.get(B).? ^ OpTou64(combo);
                registers.putAssumeCapacity(B, result);
            },
            .bst => {
                const result: u64 = @mod(getComboVal(registers, combo).?, 8);
                registers.putAssumeCapacity(B, result);
            },
            .jnz => {
                const num = registers.get(A).?;
                if (num != 0) {
                    pc = OpTou64(combo);
                }
            },
            .bxc => {
                const result = registers.get(B).? ^ registers.get(C).?;
                registers.putAssumeCapacity(B, result);
            },
            .out => {
                const result: u8 = @truncate(@mod(getComboVal(registers, combo).?, 8));
                if (expect_buf[out.items.len] != result) break;
                try out.append(result);
            },
            .bdv => {
                const num = registers.get(A).?;
                const den = try std.math.powi(u64, 2, getComboVal(registers, combo).?);
                registers.putAssumeCapacity(B, @divTrunc(num, den));
            },
            .cdv => {
                const num = registers.get(A).?;
                const den = try std.math.powi(u64, 2, getComboVal(registers, combo).?);
                registers.putAssumeCapacity(C, @divTrunc(num, den));
            },
        }
    }

    if (eqBuffers(expect_buf, out.items)) {
        return A_init_val;
    }

    const output = try genOutput(allocator, out.items);
    defer allocator.free(output);
    if (out.items.len != 0) {
        std.debug.print("{d}\n", .{A_init_val});
        std.debug.print("{s}\n", .{output});
    }

    return null;
}

fn part1(allocator: Allocator, registers_: Registers, programs: []const OpCode) !void {
    var registers = registers_;
    defer registers.deinit();

    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    var pc: u64 = 0;

    while (true) {
        if (pc >= programs.len) break;

        const op = programs[pc];
        pc += 1;
        const combo = programs[pc];
        pc += 1;

        switch (op) {
            .adv => {
                const num = registers.get(A).?;
                const den = try std.math.powi(u64, 2, getComboVal(registers, combo).?);
                registers.putAssumeCapacity(A, @divTrunc(num, den));
            },
            .bxl => {
                const result = registers.get(B).? ^ OpTou64(combo);
                registers.putAssumeCapacity(B, result);
            },
            .bst => {
                const result: u64 = @mod(getComboVal(registers, combo).?, 8);
                registers.putAssumeCapacity(B, result);
            },
            .jnz => {
                const num = registers.get(A).?;
                if (num != 0) {
                    pc = OpTou64(combo);
                }
            },
            .bxc => {
                const result = registers.get(B).? ^ registers.get(C).?;
                registers.putAssumeCapacity(B, result);
            },
            .out => {
                const result: u8 = @truncate(@mod(getComboVal(registers, combo).?, 8));
                try out.append(result);
            },
            .bdv => {
                const num = registers.get(A).?;
                const den = try std.math.powi(u64, 2, getComboVal(registers, combo).?);
                registers.putAssumeCapacity(B, @divTrunc(num, den));
            },
            .cdv => {
                const num = registers.get(A).?;
                const den = try std.math.powi(u64, 2, getComboVal(registers, combo).?);
                registers.putAssumeCapacity(C, @divTrunc(num, den));
            },
        }
    }
    const output = try genOutput(allocator, out.items);
    defer allocator.free(output);
    std.debug.print("{s}\n", .{output});
}

fn genOutput(allocator: Allocator, slice: []const u8) ![]u8 {
    var output = std.ArrayList(u8).init(allocator);
    defer output.deinit();

    for (slice, 0..) |v, i| {
        try output.append(v + '0');
        if (slice.len - 1 != i) {
            try output.append(',');
        }
    }
    return output.toOwnedSlice();
}
