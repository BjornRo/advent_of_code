const std = @import("std");
const utils = @import("utils.zig");
pub fn main() !void {
    const start = std.time.microTimestamp();
    defer std.debug.print("Time: {any}s\n", .{@as(f64, @floatFromInt(std.time.microTimestamp() - start)) / 1000_000});

    const alloc = std.heap.smp_allocator;
    const data = try utils.read(alloc, "in/d06.txt");
    defer alloc.free(data);

    const result = try solve(data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(data: []const u8) !struct { p1: usize, p2: usize } {
    var alfa: @Vector('z' - 'a' + 1, u8) = @splat(0);
    var distinct: u8 = 4;
    var p1: usize = 0;
    for (0..data.len - distinct) |i| {
        alfa = @splat(0);
        for (data[i .. i + distinct]) |elem| alfa[elem - 'a'] = 1;
        if (@reduce(.Add, alfa) == distinct) {
            if (distinct == 14) return .{ .p1 = p1, .p2 = i + distinct };
            p1 = i + distinct;
            distinct = 14;
        }
    }
    unreachable;
}
