const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const Vec2 = @Vector(2, i8);
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const alloc, const is_debug = switch (@import("builtin").mode) {
        .Debug => .{ debug_allocator.allocator(), true },
        else => .{ std.heap.smp_allocator, false },
    };
    const start = std.time.microTimestamp();
    defer {
        std.debug.print("Time: {any}s\n", .{@as(f64, @floatFromInt(std.time.microTimestamp() - start)) / 1000_000});
        if (is_debug) _ = debug_allocator.deinit();
    }

    const data = try utils.read(alloc, "in/d08.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}
fn scenic(grid: *const utils.Matrix, row: usize, col: usize) usize {
    var product: u32 = 1;
    for ([4]Vec2{ .{ 0, -1 }, .{ 0, 1 }, .{ 1, 0 }, .{ -1, 0 } }) |dir| {
        var steps: u32 = 0;
        var frontier: Vec2 = .{ @intCast(row), @intCast(col) };
        while (true) {
            frontier += dir;
            if (0 > frontier[0] or frontier[0] >= grid.rows or 0 > frontier[1] or frontier[1] >= grid.cols) break;
            steps += 1;
            if (grid.get(@intCast(frontier[0]), @intCast(frontier[1])) >= grid.get(row, col)) break;
        }
        product *= steps;
    }
    return product;
}
fn solve(alloc: Allocator, data: []u8) !struct { p1: usize, p2: usize } {
    const grid = utils.arrayToMatrix(data);

    var map = std.AutoHashMap(struct { usize, usize }, void).init(alloc);
    defer map.deinit();
    const Start = [2]struct { usize, Vec2 };
    for (1..grid.rows - 1) |i| {
        for (Start{ .{ 0, Vec2{ 0, 1 } }, .{ grid.cols - 1, Vec2{ 0, -1 } } }) |e| {
            var curr = grid.get(i, e[0]);
            var frontier: Vec2 = .{ @intCast(i), @intCast(e[0]) };
            while (true) {
                frontier += e[1];
                if (0 > frontier[1] or frontier[1] >= grid.cols) break;
                const elem = grid.get(i, @intCast(frontier[1]));
                if (elem <= curr) continue;
                curr = elem;
                try map.put(.{ i, @intCast(frontier[1]) }, {});
            }
        }
        for (Start{ .{ 0, Vec2{ 1, 0 } }, .{ grid.rows - 1, Vec2{ -1, 0 } } }) |e| {
            var curr = grid.get(e[0], i);
            var frontier: Vec2 = .{ @intCast(e[0]), @intCast(i) };
            while (true) {
                frontier += e[1];
                if (0 > frontier[0] or frontier[0] >= grid.rows) break;
                const elem = grid.get(@intCast(frontier[0]), i);
                if (elem <= curr) continue;
                curr = elem;
                try map.put(.{ @intCast(frontier[0]), i }, {});
            }
        }
    }
    var total: usize = 0;
    for (0..grid.rows) |i| for (0..grid.cols) |j| {
        const result = scenic(&grid, i, j);
        if (result > total) total = result;
    };
    return .{ .p1 = grid.rows * 2 + grid.cols * 2 - 4 + map.count(), .p2 = total };
}
