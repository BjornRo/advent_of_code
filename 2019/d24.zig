const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const Visited = std.AutoHashMap(u32, void);
const Depth = std.AutoHashMap(i16, [][]u8);

inline fn matrixToKey(mat: []const []const u8) u32 {
    var key: u32 = 0;
    for (mat) |row| for (row) |col| {
        key <<= 1;
        if (col == '#') key |= 1;
    };
    return key;
}

fn part1(allocator: Allocator, const_matrix: []const []const u8) !u64 {
    var matrix = try myf.copyMatrix(allocator, const_matrix);
    var tmp_matrix = try myf.copyMatrix(allocator, const_matrix);
    var visited = Visited.init(allocator);
    defer inline for (.{ &matrix, &tmp_matrix }) |m| myf.freeMatrix(allocator, m.*);
    defer visited.deinit();

    while (true) {
        if ((try visited.getOrPut(matrixToKey(matrix))).found_existing) {
            var sum: u64 = 0;
            for (matrix, 0..) |row, i| for (row, 0..) |elem, j| {
                const index = i * matrix[0].len + j;
                if (elem == '#') sum += try std.math.powi(u64, 2, index);
            };
            return sum;
        }

        for (0..matrix.len) |i| for (matrix[i], 0..) |elem, j| {
            var bugs: u8 = 0;
            for (myf.getNextPositions(@as(i8, @intCast(i)), @as(i8, @intCast(j)))) |next_pos|
                if (myf.checkInBounds(i8, next_pos, @intCast(matrix.len), @intCast(matrix[0].len))) |valid| {
                    if (matrix[valid.row][valid.col] == '#') bugs += 1;
                };

            tmp_matrix[i][j] = if (elem == '#' and bugs != 1)
                '.'
            else if (elem == '.' and (bugs == 1 or bugs == 2))
                '#'
            else
                elem;
        };
        const t = matrix;
        matrix = tmp_matrix;
        tmp_matrix = t;
    }
}

fn gridception(
    allocator: Allocator,
    dim: u8,
    depth_map: *Depth,
    depth: i16,
    direction: enum { None, Up, Down },
    minutes: u16,
) !void {
    if (@abs(depth) > (minutes / 2)) return;

    const matrix = blk: {
        const res = try depth_map.getOrPut(depth);
        if (!res.found_existing)
            res.value_ptr.* = try myf.initValueMatrix(allocator, dim, dim, @as(u8, '.'));
        break :blk res.value_ptr.*;
    };

    var tmp_matrix = try myf.copyMatrix(allocator, matrix);
    defer {
        myf.freeMatrix(allocator, matrix);
        depth_map.putAssumeCapacity(depth, tmp_matrix);
    }

    const depth_plus: ?[]const []const u8 = depth_map.get(depth + 1);
    const depth_minus: ?[]const []const u8 = depth_map.get(depth - 1);

    const half_dim = dim / 2;
    for (0..matrix.len) |i| for (matrix[i], 0..) |elem, j| {
        if (i == half_dim and j == half_dim) continue;
        var bugs: u8 = 0;

        for (myf.getNeighborOffset(i8)) |offset| {
            const dr, const dc = offset;
            const nr = @as(i8, @intCast(i)) + dr;
            const nc = @as(i8, @intCast(j)) + dc;
            if (0 <= nr and nr < dim and 0 <= nc and nc < dim) {
                if (nc != half_dim or nr != half_dim) {
                    if (matrix[@intCast(nr)][@intCast(nc)] == '#') bugs += 1;
                } else if (depth_plus) |next_grid| {
                    if (dc != 0) {
                        const col = if (dc == -1) dim - 1 else 0;
                        for (0..5) |k| {
                            if (next_grid[k][col] == '#') bugs += 1;
                        }
                    } else if (dr != 0) {
                        const row = if (dr == -1) dim - 1 else 0;
                        for (0..5) |k| {
                            if (next_grid[row][k] == '#') bugs += 1;
                        }
                    }
                }
            } else if (depth_minus) |next_grid| {
                if (nr < 0) { // up
                    if (next_grid[half_dim - 1][half_dim] == '#') bugs += 1;
                } else if (dim <= nr) { // down
                    if (next_grid[half_dim + 1][half_dim] == '#') bugs += 1;
                } else if (nc < 0) { // left
                    if (next_grid[half_dim][half_dim - 1] == '#') bugs += 1;
                } else if (dim <= nc) { // right
                    if (next_grid[half_dim][half_dim + 1] == '#') bugs += 1;
                }
            }
        }
        tmp_matrix[i][j] = if (elem == '#' and bugs != 1)
            '.'
        else if (elem == '.' and (bugs == 1 or bugs == 2))
            '#'
        else
            elem;
    };

    switch (direction) {
        .None => {
            try gridception(allocator, dim, depth_map, depth + 1, .Up, minutes);
            try gridception(allocator, dim, depth_map, depth - 1, .Down, minutes);
        },
        .Up => try gridception(allocator, dim, depth_map, depth + 1, .Up, minutes),
        .Down => try gridception(allocator, dim, depth_map, depth - 1, .Down, minutes),
    }
}

fn part2(allocator: Allocator, matrix: []const []const u8) !u16 {
    var depth = Depth.init(allocator);
    defer depth.deinit();

    try depth.put(0, try myf.copyMatrix(allocator, matrix));
    for (0..200) |i| try gridception(allocator, @intCast(matrix.len), &depth, 0, .None, @intCast(i + 2));

    var sum: u16 = 0;
    var v_it = depth.valueIterator();
    while (v_it.next()) |v| {
        for (v.*) |row| for (row) |e| {
            if (e == '#') sum += 1;
        };
        myf.freeMatrix(allocator, v.*);
    }
    return sum;
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    const matrix = try allocator.alloc([]const u8, input_attributes.row_len);
    defer allocator.free(matrix);

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    for (matrix) |*row| row.* = in_iter.next().?;

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        try part1(allocator, matrix),
        try part2(allocator, matrix),
    });
}
