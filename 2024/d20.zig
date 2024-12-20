const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const CT = i16;

const Point = struct {
    row: CT,
    col: CT,

    const Self = @This();

    fn init(row: anytype, col: anytype) Self {
        return .{ .row = @intCast(row), .col = @intCast(col) };
    }
    fn cast(self: Self) [2]u16 {
        return .{ @intCast(self.row), @intCast(self.col) };
    }
    fn eq(self: Self, o: Point) bool {
        return self.row == o.row and self.col == o.col;
    }
    fn toArr(self: Self) [2]CT {
        return .{ self.row, self.col };
    }
};

fn inBounds(p: Point, dim: anytype) bool {
    const r, const c = p.toArr();
    const tdim: @TypeOf(r) = @intCast(dim);
    return 0 <= r and 0 <= c and r < tdim and c < tdim;
}

fn getOffset2Pos(point: Point) [4]Point {
    const T = @TypeOf(point.row);
    const row, const col = point.toArr();
    const a = @Vector(8, T){ row, col, row, col, row, col, row, col };
    const b = @Vector(8, T){ 2, 0, 0, 2, -2, 0, 0, -2 };
    const res: [8]T = a + b;
    const resT: [4][2]T = @bitCast(res);
    var result: [4]Point = undefined;
    for (resT, 0..) |coords, i| result[i] = Point{ .row = coords[0], .col = coords[1] };
    return result;
}

fn getNextPositions(point: Point) [4]Point {
    const T = @TypeOf(point.row);
    const row, const col = point.toArr();
    const a = @Vector(8, T){ row, col, row, col, row, col, row, col };
    const b = @Vector(8, T){ 1, 0, 0, 1, -1, 0, 0, -1 };
    const res: [8]T = a + b;
    const resT: [4][2]T = @bitCast(res);
    var result: [4]Point = undefined;
    for (resT, 0..) |coords, i| result[i] = Point{ .row = coords[0], .col = coords[1] };
    return result;
}

const kernel = 41;
const center: i8 = @intCast(kernel / 2);
const manhattan_circle = blk: {
    @setEvalBranchQuota(2000);
    var flat_circle = [_]u8{0} ** (kernel * kernel);
    const circle = @as(*[kernel][kernel]u8, @ptrCast(&flat_circle));
    for (0..kernel) |i| {
        for (0..kernel) |j| {
            const i_: i8 = @intCast(i);
            const j_: i8 = @intCast(j);
            const dst: u8 = @intCast(@abs(center - i_) + @abs(center - j_));
            if (2 <= dst and dst <= center) circle[i][j] = dst;
        }
    }
    break :blk circle.*;
};

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [70_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    const dim: u8 = @intCast(input_attributes.row_len);

    const matrix = try allocator.alloc([]u8, dim);
    defer allocator.free(matrix);

    var start_point: Point = undefined;
    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    for (matrix, 0..) |*row, i| {
        row.* = @constCast(in_iter.next().?);
        if (std.mem.indexOfScalar(u8, row.*, 'S')) |j| start_point = Point.init(i, j);
    }

    var count_matrix = try myf.initValueMatrix(allocator, dim, dim, @as(u16, 0));
    defer myf.freeMatrix(allocator, count_matrix);
    var frontier = start_point;
    var steps: u16 = 0;
    var visited = frontier;
    while (true) {
        const row, const col = frontier.cast();
        if (matrix[row][col] == 'E') break;

        for (getNextPositions(frontier)) |next_pos| {
            const next_row, const next_col = next_pos.cast();
            if (matrix[next_row][next_col] == '#') continue;
            if (visited.eq(next_pos)) continue;
            steps += 1;
            visited = frontier;
            frontier = next_pos;
            count_matrix[next_row][next_col] = steps;
            break;
        }
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        fast_part1(matrix, count_matrix, start_point),
        solver(matrix, count_matrix, start_point),
    });
}

fn fast_part1(
    matrix: []const []const u8,
    count_matrix: []const []const u16,
    start_point: Point,
) u16 {
    var cheats: u16 = 0;
    var frontier = start_point;
    var visited = frontier;
    while (true) {
        const row, const col = frontier.cast();
        if (matrix[row][col] == 'E') break;

        for (getOffset2Pos(frontier)) |offset_pos| {
            if (!inBounds(offset_pos, matrix.len)) continue;
            const next_row, const next_col = offset_pos.cast();
            const this_count = count_matrix[row][col] + 2;
            const next_count = count_matrix[next_row][next_col];
            if (next_count > this_count) {
                if (next_count - this_count >= 100) cheats += 1;
            }
        }

        for (getNextPositions(frontier)) |next_pos| {
            const next_row, const next_col = next_pos.cast();
            if (matrix[next_row][next_col] == '#') continue;
            if (visited.eq(next_pos)) continue;
            visited = frontier;
            frontier = next_pos;
            break;
        }
    }
    return cheats;
}

fn solver(
    matrix: []const []const u8,
    count_matrix: []const []const u16,
    start_point: Point,
) u32 {
    var cheats: u32 = 0;
    var frontier = start_point;
    var visited = frontier;
    while (true) {
        const row, const col = frontier.cast();
        if (matrix[row][col] == 'E') break;

        var next_iter = validNeighborsIter(frontier, matrix.len, matrix.len);
        while (next_iter.next()) |next_pos| {
            const next_row, const next_col, const dst = next_pos;
            const this_count = count_matrix[row][col] + dst;
            const next_count = count_matrix[next_row][next_col];
            if (next_count > this_count) {
                if (next_count - this_count >= 100) cheats += 1;
            }
        }
        for (getNextPositions(frontier)) |next_pos| {
            const next_row, const next_col = next_pos.cast();
            if (matrix[next_row][next_col] == '#') continue;
            if (visited.eq(next_pos)) continue;
            visited = frontier;
            frontier = next_pos;
            break;
        }
    }
    return cheats;
}

pub fn ValidNeighborsIterator() type {
    return struct {
        point: Point,
        max_row: usize,
        max_col: usize,
        product: usize,
        index: usize,

        const Self = @This();

        pub fn next(self: *Self) ?[3]u16 {
            while (self.index < self.product) {
                defer self.index += 1;
                const i = self.index / kernel;
                const j = @mod(self.index, kernel);
                const row: @TypeOf(self.point.row) = @intCast(i);
                const col: @TypeOf(self.point.col) = @intCast(j);

                const dist = manhattan_circle[i][j];
                if (2 <= dist) {
                    const next_row = row - center + self.point.row;
                    const next_col = col - center + self.point.col;
                    if (0 <= next_row and next_row < self.max_row and
                        0 <= next_col and next_col < self.max_col)
                        return .{ @intCast(next_row), @intCast(next_col), dist };
                }
            }

            return null;
        }
    };
}
pub fn validNeighborsIter(
    point: Point,
    max_row: usize,
    max_col: usize,
) ValidNeighborsIterator() {
    comptime if (kernel % 2 == 0)
        @compileError("The number is even, which is not allowed.");

    return .{
        .point = point,
        .max_row = max_row,
        .max_col = max_col,
        .product = kernel * kernel,
        .index = 0,
    };
}
