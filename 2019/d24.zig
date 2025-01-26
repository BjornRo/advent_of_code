const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

pub fn matrixToKey(mat: []const []const u8) u32 {
    var key: u32 = 0;
    for (mat) |row| for (row) |col| {
        key <<= 1;
        if (col == '#') key |= 1;
    };
    return key;
}
const HashCtx = struct {
    pub fn hash(_: @This(), key: u32) u64 {
        return myf.hashU64(key);
    }
    pub fn eql(_: @This(), a: u32, b: u32) bool {
        return a == b;
    }
};
const Visited = std.HashMap(u32, void, HashCtx, 90);
fn part1(allocator: Allocator, const_matrix: []const []const u8) !void {
    var matrix = try myf.copyMatrix(allocator, const_matrix);
    var tmp = try myf.copyMatrix(allocator, const_matrix);
    var visited = Visited.init(allocator);
    defer inline for (.{ &matrix, &tmp }) |m| myf.freeMatrix(allocator, m.*);
    defer visited.deinit();

    while (true) {
        defer {
            const t = matrix;
            matrix = tmp;
            tmp = t;
        }
        const key = matrixToKey(matrix);
        if ((try visited.getOrPut(key)).found_existing) {
            var sum: u64 = 0;
            for (matrix, 0..) |row, i| {
                for (row, 0..) |elem, j| {
                    const index = i * matrix[0].len + j;
                    if (elem == '#') sum += try std.math.powi(u64, 2, index);
                }
            }
            print(sum);
            return;
        }

        for (0..matrix.len) |i| {
            for (matrix[i], 0..) |elem, j| {
                var bugs: u8 = 0;
                for (myf.getNextPositions(@as(i8, @intCast(i)), @as(i8, @intCast(j)))) |next_pos| {
                    if (myf.checkInBounds(i8, next_pos, @intCast(matrix.len), @intCast(matrix[0].len))) |valid| {
                        if (matrix[valid.row][valid.col] == '#') bugs += 1;
                    }
                }
                tmp[i][j] = if (elem == '#' and bugs != 1)
                    '.'
                else if (elem == '.' and (bugs == 1 or bugs == 2))
                    '#'
                else
                    elem;
            }
        }
    }
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

    // try part1(allocator, matrix);

    var depth = Depth.init(allocator);
    defer {
        var v_it = depth.valueIterator();
        while (v_it.next()) |m| myf.freeMatrix(allocator, m.*);
        depth.deinit();
    }
    try depth.put(0, try myf.copyMatrix(allocator, matrix));

    // const neighbors = DepthNeighbors.init(0, 0, 0, 0);
    try part2(allocator, @intCast(matrix.len), &depth, 0, 2);

    // std.debug.print("{s}\n", .{input});
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

const Depth = std.AutoHashMap(i16, [][]u8);
// const DepthNeighbors = struct {
//     up: u8,
//     down: u8,
//     left: u8,
//     right: u8,

//     const Self = @This();
//     fn init(up: u8, down: u8, left: u8, right: u8) Self {
//         return DepthNeighbors{ .up = up, .down = down, .left = left, .right = right };
//     }
// };

fn part2(
    allocator: Allocator,
    dim: u8,
    depth_map: *Depth,
    depth: i16,
    minutes: u16,
) !void {
    const map_result = try depth_map.getOrPut(depth);
    if (!map_result.found_existing) {
        // map_result.value_ptr.* = myf.initValueMatrix(allocator, dim, dim, @as(u8, '.'));
        return;
    }
    const matrix = map_result.value_ptr.*;
    var tmp = try myf.copyMatrix(allocator, matrix);
    defer {
        myf.freeMatrix(allocator, map_result.value_ptr.*);
        map_result.value_ptr.* = tmp;
    }

    var depth_plus: ?[]const []const u8 = null;
    var depth_minus: ?[]const []const u8 = null;
    if (@abs(depth + 1) <= (minutes / 2)) {
        const depth_res = try depth_map.getOrPut(depth + 1);
        if (!depth_res.found_existing) {
            depth_res.value_ptr.* = try myf.initValueMatrix(allocator, dim, dim, @as(u8, '.'));
        }
        depth_plus = depth_res.value_ptr.*;
    }
    if (@abs(depth - 1) <= (minutes / 2)) {
        const depth_res = try depth_map.getOrPut(depth - 1);
        if (!depth_res.found_existing) {
            depth_res.value_ptr.* = try myf.initValueMatrix(allocator, dim, dim, @as(u8, '.'));
        }
        depth_minus = depth_res.value_ptr.*;
    }
    std.debug.print("{d} {any} {any}\n", .{ depth, depth_plus, depth_minus });

    const half_dim = dim / 2;
    for (0..matrix.len) |i| {
        for (matrix[i], 0..) |elem, j| {
            if (i == half_dim and j == half_dim) continue;
            var bugs: u8 = 0;
            defer {
                tmp[i][j] = if (elem == '#' and bugs != 1)
                    '.'
                else if (elem == '.' and (bugs == 1 or bugs == 2))
                    '#'
                else
                    elem;
            }
            const ii = @as(i8, @intCast(i));
            const jj = @as(i8, @intCast(j));
            for (myf.getNeighborOffset(i8)) |offset| {
                const dr, const dc = offset;
                const nr = ii + dr;
                const nc = jj + dc;
                if (0 <= nr and nr < dim and 0 <= nc and nc < dim) {
                    if (nc == half_dim and nr == half_dim) {
                        if (depth_minus) |next_grid| {
                            if (dc == -1) {
                                for (0..5) |k| {
                                    if (next_grid[k][dim - 1] == '#') bugs += 1;
                                }
                            } else if (dc == 1) {
                                for (0..5) |k| {
                                    if (next_grid[k][0] == '#') bugs += 1;
                                }
                            } else if (dr == -1) {
                                for (0..5) |k| {
                                    if (next_grid[dim - 1][k] == '#') bugs += 1;
                                }
                            } else if (dr == 1) {
                                for (0..5) |k| {
                                    if (next_grid[0][k] == '#') bugs += 1;
                                }
                            }
                        }
                    } else if (matrix[@intCast(nr)][@intCast(nc)] == '#') bugs += 1;
                } else {
                    if (depth_plus) |next_grid| {
                        if (nr < 0) { // up
                            if (next_grid[half_dim - 1][half_dim] == '#') bugs += 1;
                        } else if (dim < nr) { // down
                            if (next_grid[half_dim + 1][half_dim] == '#') bugs += 1;
                        } else if (nc < 0) { // left
                            if (next_grid[half_dim][half_dim - 1] == '#') bugs += 1;
                        } else if (dim < nc) { // right
                            if (next_grid[half_dim][half_dim + 1] == '#') bugs += 1;
                        }
                    }
                }
            }
        }
    }

    try part2(allocator, dim, depth_map, depth + 1, minutes);
    try part2(allocator, dim, depth_map, depth - 1, minutes);
}
