const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Allocator = std.mem.Allocator;

fn get_value(value: anytype, comptime param_num: usize, op: []const i32, i: usize) @TypeOf(value) {
    const factor: @TypeOf(value) = switch (param_num) {
        1 => 100,
        2 => 1000,
        else => unreachable,
    };
    const idx = i + param_num;
    return if (@mod(@divFloor(value, factor), 10) == 0) op[@intCast(op[idx])] else op[idx];
}

fn machine(allocator: Allocator, ops: []i32, input_value: @TypeOf(ops[0])) !@TypeOf(ops[0]) {
    var op = try allocator.alloc(@TypeOf(ops[0]), ops.len);
    defer allocator.free(op);
    @memcpy(op, ops);

    const input: @TypeOf(op[0]) = input_value;
    var output: @TypeOf(op[0]) = 0;

    var i: u32 = 0;
    while (true) {
        const value = op[i];
        switch (@mod(value, 100)) {
            1 => {
                op[@intCast(op[i + 3])] = get_value(value, 1, op, i) + get_value(value, 2, op, i);
                i += 4;
            },
            2 => {
                op[@intCast(op[i + 3])] = get_value(value, 1, op, i) * get_value(value, 2, op, i);
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
                i = if (get_value(value, 1, op, i) != 0) @intCast(get_value(value, 2, op, i)) else i + 3;
            },
            6 => {
                i = if (get_value(value, 1, op, i) == 0) @intCast(get_value(value, 2, op, i)) else i + 3;
            },
            7 => {
                op[@intCast(op[i + 3])] = if (get_value(value, 1, op, i) < get_value(value, 2, op, i)) 1 else 0;
                i += 4;
            },
            8 => {
                op[@intCast(op[i + 3])] = if (get_value(value, 1, op, i) == get_value(value, 2, op, i)) 1 else 0;
                i += 4;
            },
            99 => break,
            else => unreachable,
        }
    }
    return output;
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [10_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    var op_list = std.ArrayList(i32).init(allocator);
    defer op_list.deinit();

    var in_iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\n"), ',');
    while (in_iter.next()) |raw_value| try op_list.append(try std.fmt.parseInt(i32, raw_value, 10));

    std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{
        try machine(allocator, op_list.items, 1),
        try machine(allocator, op_list.items, 5),
    });
}
