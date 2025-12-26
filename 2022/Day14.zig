const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const Point = struct {
    row: u32 = 0,
    col: u32 = 0,
    const Self = @This();
    fn unpack(self: Self) [2]@TypeOf(self.row) {
        return .{ self.row, self.col };
    }
    fn parse(s: []const u8) Self {
        var iter: utils.NumberIter(u32) = .{ .string = s };
        const col = iter.next().?;
        const row = iter.next().?;
        return .{ .row = row, .col = col };
    }
};
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d14.txt");
    defer alloc.free(data);

    std.debug.print("Part 1: {d}\n", .{try solve(alloc, data, false)});
    std.debug.print("Part 2: {d}\n", .{try solve(alloc, data, true) + 1});
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
                max.row = @max(max.row, point.row + 1 + 2);
                max.col = @max(max.col, point.col + 1 + 8 + 400);
                min.row = 0;
                min.col = @min(min.col, point.col - 5 - 400);
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
            .row = max.row - min.row,
            .col = max.col - min.col,
        },
        .start = start,
        .list = list,
    };
}
fn solve(alloc: Allocator, data: []const u8, part2: bool) !usize {
    const parsed = try parse(alloc, data);
    defer alloc.free(parsed.list);

    var matrix = try utils.Matrix.empty(alloc, @intCast(parsed.grid_dim.row), @intCast(parsed.grid_dim.col));
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
    if (part2) for (0..matrix.cols) |c| matrix.set(matrix.rows - 1, c, '#');

    while (true) {
        var settled = true;
        const row, const col = parsed.start.unpack();
        var drow: i64 = @intCast(row);
        var dcol: i64 = @intCast(col);
        while (true) : (drow += 1) {
            if (!matrix.inBounds(drow, dcol)) break;
            if (matrix.get(@intCast(drow), @intCast(dcol)) != 0) {
                for ([2]i64{ -1, 1 }) |delta| {
                    if (!matrix.inBounds(drow, dcol + delta)) break;
                    if (matrix.get(@intCast(drow), @intCast(dcol + delta)) == 0) {
                        dcol += delta;
                        break;
                    }
                } else {
                    drow -= 1;
                    settled = false;
                    break;
                }
            }
        }
        if (settled) break;
        if (part2)
            if (drow == 0) break;
        matrix.set(@intCast(drow), @intCast(dcol), 'o');
    }

    return std.mem.count(u8, matrix.data, "o");
}

// var queue: Deque(struct { enum { Fill, Fall }, Point }) = try .init(alloc);
// defer queue.deinit();
// try queue.pushBack(.{ .Fall, parsed.start });

// outer: while (queue.popFront()) |curr| {
//     const state, const point = curr;
//     const row, const col = point.unpack();
//     if (state == .Fall) {
//         var drow = row + 1;
//         while (true) {
//             if (!matrix.inBounds(drow, col)) continue :outer;
//             if (matrix.get(drow, col) != 0) break;
//             drow += 1;
//         }
//         matrix.set(drow, col, 'o');
//         //
//     }
//     break;
// }
