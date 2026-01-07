const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d25.txt");
    defer alloc.free(data);
    var res = try solve(alloc, data);
    defer res.deinit(alloc);
    std.debug.print("Part 1: {s}\n", .{res.items});
}

fn solve(alloc: Allocator, data: []const u8) !std.ArrayList(u8) {
    var total: isize = 0;
    var split_iter = std.mem.splitScalar(u8, data, '\n');
    while (split_iter.next()) |item| total += convert(item);
    return try toSnafu(alloc, total);
}
fn convert(row: []const u8) isize {
    var total: isize = 0;
    var mul: isize = 1;
    for (0..row.len) |i| {
        const r = switch (row[row.len - i - 1]) {
            '-' => -mul,
            '=' => -mul * 2,
            else => |v| mul * (v - '0'),
        };
        total += r;
        mul *= 5;
    }
    return total;
}
fn toSnafu(alloc: Allocator, value: isize) !std.ArrayList(u8) {
    var list: std.ArrayList(u8) = .empty;
    var val = value;
    while (val != 0) {
        const n: i8 = @intCast(@mod(val, 5));
        try list.append(alloc, if (n >= 3) (if (n == 3) '=' else '-') else '0' + @as(u8, @intCast(n)));
        val = @divFloor(val - if (n >= 3) n - 5 else n, 5);
    }
    std.mem.reverse(u8, list.items);
    return list;
}
