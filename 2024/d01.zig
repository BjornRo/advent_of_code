const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const builtin = @import("builtin");
const expect = std.testing.expect;
const time = std.time;

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000_000);
        writer.print("\nTime taken: {d:.10}s\n", .{elapsed}) catch {};
    }
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    // const allocator = gpa.allocator();
    var buffer: [70_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getFirstAppArg(allocator);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    var left = std.ArrayList(i32).init(allocator);
    var right = std.ArrayList(i32).init(allocator);
    defer inline for (.{ left, right }) |res| res.deinit();

    var counter = std.AutoHashMap(i32, i32).init(allocator);
    defer counter.deinit();

    const delim = if (try myf.getDelimType(input) == .CRLF) "\r\n" else "\n";
    var input_iter = std.mem.splitSequence(u8, input, delim);
    while (input_iter.next()) |row| {
        if (row.len == 0) continue;
        var row_iter = std.mem.splitSequence(u8, row, " " ** 3);
        const _left = try std.fmt.parseInt(i32, row_iter.next().?, 10);
        const _right = try std.fmt.parseInt(i32, row_iter.next().?, 10);

        try left.append(_left);
        try right.append(_right);

        const count = counter.get(_right) orelse 0;
        try counter.put(_right, count + 1);
    }
    std.mem.sort(i32, left.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, right.items, {}, std.sort.asc(i32));

    var p1_sum: i64 = 0;
    var p2_sum: i64 = 0;
    for (left.items, right.items) |left_elem, right_elem| {
        p1_sum += @abs(left_elem - right_elem);
        p2_sum += left_elem * (counter.get(left_elem) orelse 0);
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}
