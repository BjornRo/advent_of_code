const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

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

    const dim = input_attributes.row_len;

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    const matrix = blk: {
        var i: u8 = 0;
        const matrix = try myf.initValueMatrix(allocator, dim, dim, @as(u8, '.'));
        while (in_iter.next()) |row| {
            @memcpy(matrix[i], row);
            i += 1;
        }
        break :blk matrix;
    };
    defer myf.freeMatrix(allocator, matrix);
    try part1(allocator, matrix);

    // std.debug.print("{s}\n", .{input});
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

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

    //
}
