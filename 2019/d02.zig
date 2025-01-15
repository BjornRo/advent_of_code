const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Allocator = std.mem.Allocator;

fn machine(allocator: Allocator, ops: []u32, noun: u32, verb: u32) !u32 {
    var op = try allocator.alloc(u32, ops.len);
    defer allocator.free(op);
    @memcpy(op, ops);

    op[1] = noun;
    op[2] = verb;

    var i: u32 = 0;
    while (true) {
        op[op[i + 3]] = switch (op[i]) {
            1 => op[op[i + 1]] + op[op[i + 2]],
            2 => op[op[i + 1]] * op[op[i + 2]],
            99 => return op[0],
            else => unreachable,
        };
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
    var buffer: [3_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    var op_list = std.ArrayList(u32).init(allocator);
    defer op_list.deinit();

    var in_iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\n"), ',');
    while (in_iter.next()) |raw_value| try op_list.append(try std.fmt.parseInt(u32, raw_value, 10));

    var p2: usize = 0;
    outer: for (0..100) |i| {
        for (0..100) |j| {
            if (try machine(allocator, op_list.items, @intCast(i), @intCast(j)) == 19690720) {
                p2 = 100 * i + j;
                break :outer;
            }
        }
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        try machine(allocator, op_list.items, 12, 2),
        p2,
    });
}
