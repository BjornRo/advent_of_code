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
    const param_1 = @mod(@divFloor(value, 100), 10);
    const param_2 = @mod(@divFloor(value, 1000), 10);
    const param_3 = @mod(@divFloor(value, 10000), 10);
    return .{ .op = op_code, .p1 = param_1, .p2 = param_2, .p3 = param_3 };
}

fn machine(allocator: Allocator, ops: []i32) !@TypeOf(ops[0]) {
    var op = try allocator.alloc(i32, ops.len);
    defer allocator.free(op);
    @memcpy(op, ops);

    const input: @TypeOf(ops[0]) = 5;
    var output: @TypeOf(ops[0]) = 0;

    var i: u32 = 0;
    while (true) {
        const mode_op = get_op(op[i]);
        switch (mode_op.op) {
            1 => {
                const param_1 = if (mode_op.p1 == 0) op[@intCast(op[i + 1])] else op[i + 1];
                const param_2 = if (mode_op.p2 == 0) op[@intCast(op[i + 2])] else op[i + 2];
                op[@intCast(op[i + 3])] = param_1 + param_2;
                i += 4;
            },
            2 => {
                const param_1 = if (mode_op.p1 == 0) op[@intCast(op[i + 1])] else op[i + 1];
                const param_2 = if (mode_op.p2 == 0) op[@intCast(op[i + 2])] else op[i + 2];
                op[@intCast(op[i + 3])] = param_1 * param_2;
                i += 4;
            },
            3 => {
                op[@intCast(op[i + 1])] = input;
                i += 2;
            },
            4 => {
                output = op[@intCast(op[i + 1])];
                i += 2;
            },
            5 => {
                const param_1 = if (mode_op.p1 == 0) op[@intCast(op[i + 1])] else op[i + 1];
                if (param_1 != 0) {
                    const param_2 = if (mode_op.p2 == 0) op[@intCast(op[i + 2])] else op[i + 2];
                    i = @intCast(param_2);
                } else {
                    i += 3;
                }
            },
            6 => {
                const param_1 = if (mode_op.p1 == 0) op[@intCast(op[i + 1])] else op[i + 1];
                if (param_1 == 0) {
                    const param_2 = if (mode_op.p2 == 0) op[@intCast(op[i + 2])] else op[i + 2];
                    i = @intCast(param_2);
                } else {
                    i += 3;
                }
            },
            7 => {
                const param_1 = if (mode_op.p1 == 0) op[@intCast(op[i + 1])] else op[i + 1];
                const param_2 = if (mode_op.p2 == 0) op[@intCast(op[i + 2])] else op[i + 2];
                if (param_1 < param_2) {
                    op[@intCast(op[i + 3])] = 1;
                } else {
                    op[@intCast(op[i + 3])] = 0;
                }
                i += 4;
            },
            8 => {
                const param_1 = if (mode_op.p1 == 0) op[@intCast(op[i + 1])] else op[i + 1];
                const param_2 = if (mode_op.p2 == 0) op[@intCast(op[i + 2])] else op[i + 2];
                if (param_1 == param_2) {
                    op[@intCast(op[i + 3])] = 1;
                } else {
                    op[@intCast(op[i + 3])] = 0;
                }
                i += 4;
            },
            99 => {
                break;
            },
            else => unreachable,
        }
    }

    print(op);
    print(input);
    print(output);
    return 1;
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

    _ = try machine(allocator, op_list.items);

    // std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{
    //     try machine(allocator, op_list.items, 12, 2),
    //     p2,
    // });
}
