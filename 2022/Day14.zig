const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const Point = struct {
    row: u16 = 0,
    col: u16 = 0,
    const Self = @This();
    fn parse(s: []const u8) Self {
        var iter: utils.NumberIter(u16) = .{ .string = s };
        const col = iter.next().?;
        const row = iter.next().?;
        return .{ .row = row, .col = col };
    }
};
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d14t.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn parse(alloc: Allocator, data: []const u8) !struct { grid_dim: Point, start: Point, list: []?Point } {
    var start: Point = .{ .row = 0, .col = 500 };
    var min: Point = .{
        .row = std.math.maxInt(@TypeOf((Point{}).row)),
        .col = std.math.maxInt(@TypeOf((Point{}).row)),
    };
    var max: Point = .{ .row = 0, .col = 0 };

    const list = blk: {
        var list: std.ArrayList(?Point) = .empty;
        defer list.deinit(alloc);
        var split_iter = std.mem.splitScalar(u8, data, '\n');
        while (split_iter.next()) |item| {
            var row_iter = std.mem.splitSequence(u8, item, " -> ");
            while (row_iter.next()) |raw_dots| {
                const point: Point = .parse(raw_dots);
                // 1 for "padding"
                max.row = @max(max.row, point.row + 1);
                max.col = @max(max.col, point.col + 1);
                min.row = @min(min.row, point.row - 2); // Give start 1 space
                min.col = @min(min.col, point.col - 1);
                try list.append(alloc, point);
            }
            try list.append(alloc, null);
        }

        break :blk try list.toOwnedSlice(alloc);
    };

    start.col -= min.col;
    for (list) |*p|
        if (p.*) |*point| {
            point.col -= min.col;
            point.row -= min.row;
        };
    return .{
        .grid_dim = .{
            .row = max.row - min.row, // This is either out of bounds or exit. (Max row)
            .col = max.col - min.col + 1, // 1 additional spot to the right, left is added already.
        },
        .start = start,
        .list = list,
    };
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    const parsed = try parse(alloc, data);
    defer alloc.free(parsed.list);
    std.debug.print("{any}\n", .{parsed.grid_dim});
    std.debug.print("{any}\n", .{parsed.list});

    var matrix: utils.Matrix = .{
        .data = try alloc.alloc(u8, @as(u32, @intCast(parsed.grid_dim.row)) * @as(u32, @intCast(parsed.grid_dim.col))),
        .rows = parsed.grid_dim.row,
        .cols = parsed.grid_dim.col,
        .stride = parsed.grid_dim.col,
    };
    defer alloc.free(matrix.data);
    {
        var curr: ?Point = null;
        for (parsed.list) |value| {
            curr = if (curr == null)
                value
            else if (value) |point|
                for (@min(curr.?.row, point.row)..@max(curr.?.row, point.row) + 1) |i| {
                    for (@min(curr.?.col, point.col)..@max(curr.?.col, point.col) + 1) |j|
                        matrix.set(i, j, '#');
                } else point
            else
                null;
        }
    }
    matrix.print(' ', '#');

    return .{ .p1 = 1, .p2 = 2 };
}
