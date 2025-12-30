const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d25.txt");
    defer alloc.free(data);
    const res = try solve(alloc, data);
    defer alloc.free(res);
    std.debug.print("Part 1: {s}\n", .{res});
}

fn solve(alloc: Allocator, data: []const u8) ![]u8 {
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
fn toSnafu(alloc: Allocator, value: isize) ![]u8 {
    var val = value;

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(alloc);

    while (val != 0) {
        const n: u8 = @intCast(@mod(val, 5));
        var fac: isize = n;
        if (n == 3) {
            fac -= 5;
            try list.append(alloc, '=');
        } else if (n == 4) {
            fac -= 5;
            try list.append(alloc, '-');
        } else {
            try list.append(alloc, '0' + n);
        }
        val = @divFloor(val - fac, 5);
    }
    std.mem.reverse(u8, list.items);
    return list.toOwnedSlice(alloc);
}
