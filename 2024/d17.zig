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
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    // const allocator = gpa.allocator();
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

    // std.debug.print("{s}\n", .{input});
}

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d17t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var in_iter = std.mem.tokenizeSequence(u8, input, double_delim);

    const raw_registers = in_iter.next().?;
    const raw_program = in_iter.next().?;

    var registers = Registers.init(allocator);
    defer registers.deinit();
    var programs = try Programs.init(allocator);
    defer programs.deinit();
    var programs2 = try Programs.init(allocator);
    defer programs2.deinit();

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
        try programs.pushBack(op);
        try programs2.pushBack(op);
    }

    try part1(try registers.clone(), programs);
}

const OpCode = enum(u4) {
    adv = 0,
    bxl = 1,
    bst = 2,
    jnz = 3,
    bxc = 4,
    out = 5,
    bdv = 6,
    cdv = 7,
};

const Registers = std.AutoArrayHashMap(u8, u64);
const Programs = Deque(OpCode);

fn part1(registers_: Registers, programs: Programs) !void {
    var registers = registers_;
    defer registers.deinit();

    printa(programs.len());
    //
}
