const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d08.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}
fn scenic(grid: [][]const u8, row: usize, col: usize) usize {
    const value = grid[row][col];
    var up: usize = 0;
    var down: usize = 0;
    var left: usize = 0;
    var right: usize = 0;
    for (0..row) |i| {
        up += 1;
        const rj = row - i - 1;
        if (grid[rj][col] >= value) break;
    }
    for (row + 1..grid.len) |i| {
        down += 1;
        if (grid[i][col] >= value) break;
    }
    for (0..col) |i| {
        left += 1;
        const lj = col - i - 1;
        if (grid[row][lj] >= value) break;
    }
    for (col + 1..grid[0].len) |j| {
        right += 1;
        if (grid[row][j] >= value) break;
    }
    return up * down * left * right;
}
fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var matrix: std.ArrayList([]const u8) = .empty;
    defer matrix.deinit(alloc);
    var splitIter = std.mem.splitScalar(u8, data, '\n');
    while (splitIter.next()) |item| try matrix.append(alloc, item);

    var map = std.AutoHashMap(struct { row: usize, col: usize }, void).init(alloc);
    defer map.deinit();

    const grid = matrix.items;
    const rows = grid[0].len;
    const cols = grid[0].len;
    for (1..rows - 1) |row| {
        var curr = grid[row][0];
        for (1..cols - 1) |col| {
            if (grid[row][col] <= curr) continue;
            try map.put(.{ .row = row, .col = col }, {});
            curr = grid[row][col];
        }
        curr = grid[row][cols - 1];
        for (1..cols - 1) |j| {
            const rcol = cols - 1 - j;
            if (grid[row][rcol] <= curr) continue;
            try map.put(.{ .row = row, .col = rcol }, {});
            curr = grid[row][rcol];
        }
    }
    for (1..cols - 1) |col| {
        var curr = grid[0][col];
        for (1..rows - 1) |row| {
            if (grid[row][col] <= curr) continue;
            try map.put(.{ .row = row, .col = col }, {});
            curr = grid[row][col];
        }
        curr = grid[rows - 1][col];
        for (1..rows - 1) |row| {
            const rrow = rows - 1 - row;
            if (grid[rrow][col] <= curr) continue;
            try map.put(.{ .row = rrow, .col = col }, {});
            curr = grid[rrow][col];
        }
    }
    var total: usize = 0;
    for (0..rows) |i| for (0..cols) |j| {
        const result = scenic(grid, i, j);
        if (result > total) total = result;
    };
    return .{ .p1 = rows * 2 + cols * 2 - 4 + map.count(), .p2 = total };
}
