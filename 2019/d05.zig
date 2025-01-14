const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

fn get_op(value: anytype) struct {
    op: @TypeOf(value),
    p1: @TypeOf(value),
    p2: @TypeOf(value),
    p3: @TypeOf(value),
} {
    const op_code = @mod(value, 100);
    const param_1 = @mod(value / 100, 10);
    const param_2 = @mod(value / 1000, 10);
    const param_3 = @mod(value / 10000, 10);
    return .{ .op = op_code, .p1 = param_1, .p2 = param_2, .p3 = param_3 };
}

fn machine(allocator: Allocator, ops: []i32) !@TypeOf(ops[0]) {
    var op = try allocator.alloc(u32, ops.len);
    defer allocator.free(op);
    @memcpy(op, ops);

    var input: @TypeOf(ops[0]) = 0;
    var output: @TypeOf(ops[0]) = 0;

    var i: u32 = 0;
    while (true) {
        switch (op[i]) {
            1 => op[i + 3] = op[op[i + 1]] + op[op[i + 2]],
            2 => op[i + 3] = op[op[i + 1]] + op[op[i + 2]],
            3 => {
                op[i + 1] = input;
            },
            4 => {
                output = op[i + 1];
            },
            99 => return op[0],
            _ => {
                //
                const iop = 1 % 100;
                _ = iop;
            },
        }
        i += 4;
    }
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    // var buffer: [3_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    var op_list = std.ArrayList(i32).init(allocator);
    defer op_list.deinit();

    var in_iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\n"), ',');
    while (in_iter.next()) |raw_value| try op_list.append(try std.fmt.parseInt(i32, raw_value, 10));

    var p2: usize = 0;
    outer: for (0..100) |i| {
        for (0..100) |j| {
            if (try machine(allocator, op_list.items, @intCast(i), @intCast(j)) == 19690720) {
                p2 = 100 * i + j;
                break :outer;
            }
        }
    }

    std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{
        try machine(allocator, op_list.items, 12, 2),
        p2,
    });
}
