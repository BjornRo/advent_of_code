const std = @import("std");
const utils = @import("utils.zig");
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const alloc, const is_debug = if (@import("builtin").mode == .Debug)
        .{ debug_allocator.allocator(), true }
    else
        .{ std.heap.smp_allocator, false };
    const start = std.time.microTimestamp();
    defer {
        std.debug.print("Time: {any}s\n", .{@as(f64, @floatFromInt(std.time.microTimestamp() - start)) / 1000_000});
        if (is_debug) _ = debug_allocator.deinit();
    }

    const data = try utils.read(alloc, "in/d01.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(allocator: std.mem.Allocator, data: []const u8) !struct { p1: u32, p2: u32 } {
    var calories: std.ArrayList(u32) = .empty;
    defer calories.deinit(allocator);

    var splitIter = std.mem.splitScalar(u8, data, '\n');
    var subSum: u32 = 0;
    while (splitIter.next()) |item| {
        if (item.len == 0) {
            try calories.append(allocator, subSum);
            subSum = 0;
        } else subSum += try std.fmt.parseUnsigned(u32, item, 10);
    }
    try calories.append(allocator, subSum);

    std.mem.sortUnstable(u32, calories.items, {}, comptime std.sort.desc(u32));
    return .{ .p1 = calories.items[0], .p2 = @reduce(.Add, @as(@Vector(3, u32), calories.items[0..3].*)) };
}
