const std = @import("std");
const myf = @import("myfunc.zig");
const Deque = @import("deque.zig").Deque;
const expect = std.testing.expect;
const time = std.time;

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000_000);
        writer.print("Time taken: {d:.10}s\n", .{elapsed}) catch {};
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();

    const filename = try myf.getFirstAppArg(allocator);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    var left = std.ArrayList(i32).init(allocator);
    var right = std.ArrayList(i32).init(allocator);
    defer inline for (.{ left, right }) |res| res.deinit();

    var input_iter = std.mem.splitAny(u8, input, "\r\n|\n");
    while (input_iter.next()) |row| {
        if (row.len == 0) continue;
        var row_iter = std.mem.splitSequence(u8, row, "   ");
        const _left = try std.fmt.parseInt(i32, row_iter.next().?, 10);
        const _right = try std.fmt.parseInt(i32, row_iter.next().?, 10);
        try left.append(_left);
        try right.append(_right);
    }
    std.mem.sort(i32, left.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, right.items, {}, std.sort.asc(i32));
    var sum: i64 = 0;
    for (left.items, 0..) |elem, i| {
        sum += @as(i64, @abs(elem - right.items[i]));
    }
    myf.printAny(sum);
}
