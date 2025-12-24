const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d06.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var set: std.AutoArrayHashMap(u8, void) = .init(alloc);
    defer set.deinit();

    var distinct: usize = 4;

    var p1: usize = 0;
    for (0..data.len - distinct) |i| {
        set.clearRetainingCapacity();
        for (data[i .. i + distinct]) |elem| try set.put(elem, {});
        if (set.count() == distinct) {
            if (distinct == 14) return .{ .p1 = p1, .p2 = i + distinct };
            p1 = i + distinct;
            distinct = 14;
        }
    }
    unreachable;
}
