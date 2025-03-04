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

fn getNextPositions(point: Point, comptime factor: i8) [4]Point {
    const T = @TypeOf(point.row);
    const row, const col = point.toArr();
    const a = @Vector(8, T){ row, col, row, col, row, col, row, col };
    const b = @Vector(8, T){ 1 * factor, 0, 0, 1 * factor, -1 * factor, 0, 0, -1 * factor };
    const res: [8]T = a + b;
    const resT: [4][2]T = @bitCast(res);
    var result: [4]Point = undefined;
    for (resT, 0..) |coords, i| result[i] = Point{ .row = coords[0], .col = coords[1] };
    return result;
}

const kernel = 41;
const center: i16 = @intCast(kernel / 2);
const manhattan_circle = blk: {
    @setEvalBranchQuota(2000);
    const remove_additional = 4; // Remove neighbors around the center
    var buf: [(kernel * (kernel + 1)) / 2 - 1 - remove_additional][3]i8 = undefined;
    var idx = 0;

    for (0..kernel) |i| {
        for (0..kernel) |j| {
            const i_: i8 = @intCast(i);
            const j_: i8 = @intCast(j);
            const dst = @abs(center - i_) + @abs(center - j_);
            if (2 <= dst and dst <= center) {
                buf[idx] = .{ center - i_, center - j_, dst };
                idx += 1;
            }
        }
    }

    break :blk buf;
};

fn fast_part1(
    matrix: []const []const u8,
    count_matrix: []const []const i16,
    start_point: Point,
) u16 {
    var cheats: u16 = 0;
    var frontier = start_point;
    var visited = frontier;
    while (true) {
        const row, const col = frontier.cast();
        if (matrix[row][col] == 'E') break;

        for (getNextPositions(frontier, 2)) |offset_pos| {
            const r, const c = offset_pos.toArr();
            const maxdim: @TypeOf(r) = @intCast(matrix.len);
            if (0 <= r and 0 <= c and r < maxdim and c < maxdim) {
                const next_row, const next_col = offset_pos.cast();
                const this_count = count_matrix[row][col] + 2;
                const next_count = count_matrix[next_row][next_col];
                if (next_count - this_count >= 100) cheats += 1;
            }
        }

        for (getNextPositions(frontier, 1)) |next_pos| {
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
    count_matrix: []const []const i16,
    start_point: Point,
) u32 {
    var cheats: u32 = 0;
    var frontier = start_point;
    var visited = frontier;
    while (true) {
        const row, const col = frontier.cast();
        if (matrix[row][col] == 'E') break;

        for (manhattan_circle) |next_pos| {
            const i, const j, const dst = next_pos;
            const next_row = i + frontier.row;
            const next_col = j + frontier.col;
            if (0 <= next_row and next_row < matrix.len and
                0 <= next_col and next_col < matrix.len)
            {
                const this_count = count_matrix[row][col] + @as(i16, @intCast(dst));
                const next_count = count_matrix[@intCast(next_row)][@intCast(next_col)];
                if (next_count - this_count >= 100) cheats += 1;
            }
        }

        for (getNextPositions(frontier, 1)) |next_pos| {
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

    var count_matrix = try myf.initValueMatrix(allocator, dim, dim, @as(i16, 0));
    defer myf.freeMatrix(allocator, count_matrix);
    var frontier = start_point;
    var visited = frontier;
    var steps: i16 = 0;
    while (true) {
        const row, const col = frontier.cast();
        if (matrix[row][col] == 'E') break;

        for (getNextPositions(frontier, 1)) |next_pos| {
            const next_row, const next_col = next_pos.cast();
            if (matrix[next_row][next_col] == '#') continue;
            if (visited.eq(next_pos)) continue;
            visited = frontier;
            frontier = next_pos;
            steps += 1;
            count_matrix[next_row][next_col] = steps;
            break;
        }
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        fast_part1(matrix, count_matrix, start_point),
        solver(matrix, count_matrix, start_point),
    });
}
