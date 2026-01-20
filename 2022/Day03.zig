const std = @import("std");
const utils = @import("utils.zig");
const contains = std.mem.containsAtLeastScalar;
pub fn main() !void {
    const start = std.time.microTimestamp();
    defer std.debug.print("Time: {any}s\n", .{@as(f64, @floatFromInt(std.time.microTimestamp() - start)) / 1000_000});

    var buf: [20000]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buf);
    const alloc = fba.allocator();

    const data = try utils.read(alloc, "in/d03.txt");
    defer alloc.free(data);

    const result = solve(data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}
fn mapper(char: u8) u16 {
    return switch (char) {
        'a'...'z' => char - ('a' - 1),
        else => char - '&',
    };
}
fn solve(data: []const u8) struct { p1: u16, p2: u16 } {
    var total1: u16 = 0;
    var total2: u16 = 0;
    var buf: [3][]const u8 = undefined;
    var groups: std.ArrayList([]const u8) = .initBuffer(&buf);
    var splitIter = std.mem.splitScalar(u8, data, '\n');
    while (splitIter.next()) |item| {
        for (item[0 .. item.len / 2]) |elem|
            if (contains(u8, item[item.len / 2 ..], 1, elem)) {
                total1 += mapper(elem);
                break;
            };
        groups.appendAssumeCapacity(item);
        if (groups.items.len != 3) continue;
        for (buf[0]) |elem| if (contains(u8, buf[1], 1, elem) and contains(u8, buf[2], 1, elem)) {
            total2 += mapper(elem);
            break;
        };
        groups.clearRetainingCapacity();
    }
    return .{ .p1 = total1, .p2 = total2 };
}
