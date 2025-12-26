const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const Point = struct {
    row: u16 = 0,
    col: u16 = 0,
    const Self = @This();
    fn unpack(self: Self) [2]@TypeOf(self.row) {
        return .{ self.row, self.col };
    }
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

    const data = try utils.read(alloc, "in/d14.txt");
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
                max.row = @max(max.row, point.row + 1);
                max.col = @max(max.col, point.col + 1);
                min.row = @min(min.row, point.row - 4); // Give start extra space
                min.col = @min(min.col, point.col);
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

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
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

    while (true) {
        var settled = true;
        const row, const col = parsed.start.unpack();
        var drow: i32 = @intCast(row);
        var dcol: i32 = @intCast(col);
        while (true) : (drow += 1) {
            if (!matrix.inBounds(drow, dcol)) break;
            if (matrix.get(@intCast(drow), @intCast(dcol)) != 0) {
                for ([2]i32{ -1, 1 }) |delta| {
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
        // std.debug.print("{d},{d},{any}\n", .{ drow, dcol, settled });
        // if (!matrix.inBounds(drow, dcol)) break;
        matrix.set(@intCast(drow), @intCast(dcol), 'o');
        // matrix.print(' ');
    }

    // matrix.print(' ');

    return .{ .p1 = std.mem.count(u8, matrix.data, "o"), .p2 = 2 };
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
