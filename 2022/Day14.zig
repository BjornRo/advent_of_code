const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const Point = struct {
    row: u16 = 0,
    col: u16 = 0,
    const Self = @This();
    fn unpack(self: Self) [2]@TypeOf(self.row) {
        return .{ self.row, self.col };
    }
    fn parse(s: []const u8) Self {
        var iter: utils.NumberIter(@TypeOf((Self{}).row)) = .{ .string = s };
        const col = iter.next().?;
        const row = iter.next().?;
        return .{ .row = row, .col = col };
    }
};
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

    const data = try utils.read(alloc, "in/d14.txt");
    defer alloc.free(data);

    std.debug.print("Part 1: {d}\n", .{try solve(alloc, data, false)});
    std.debug.print("Part 2: {d}\n", .{try solve(alloc, data, true) + 1});
}
fn parse(alloc: Allocator, data: []const u8) !struct { grid_dim: Point, start: Point, list: []?Point } {
    var min: Point = .{ .row = std.math.maxInt(@TypeOf((Point{}).row)), .col = std.math.maxInt(@TypeOf((Point{}).row)) };
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
        .start = .{ .row = 0, .col = 500 - min.col },
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
        var drow: i16 = @intCast(row);
        var dcol: i16 = @intCast(col);
        while (true) : (drow += 1) {
            if (!matrix.inBounds(drow, dcol)) break;
            if (matrix.get(@intCast(drow), @intCast(dcol)) != 0) {
                for ([2]i16{ -1, 1 }) |delta| {
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
        if (settled or (part2 and drow == 0)) break;
        matrix.set(@intCast(drow), @intCast(dcol), 'o');
    }
    const len = std.simd.suggestVectorLength(u8).?;
    const Vec = @Vector(len, u8);
    const needles: Vec = @splat('o');
    var count: u32 = 0;
    var i: u32 = 0;
    while (i + len <= matrix.data.len) : (i += len)
        count += @popCount(@as(std.meta.Int(.unsigned, len), @bitCast(@as(Vec, matrix.data[i..][0..len].*) == needles)));
    while (i < matrix.data.len) : (i += 1) {
        if (matrix.data[i] == 'o') count += 1;
    }
    return count;
}
