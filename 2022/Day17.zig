const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d17t.txt");
    defer alloc.free(data);

    try part1(alloc, data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(_: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var split_iter = std.mem.splitScalar(u8, data, '\n');
    while (split_iter.next()) |_| {
        //
    }

    return .{ .p1 = 1, .p2 = 2 };
}
const rocks: [5][]const []const u8 = .{
    &.{"####"},
    &.{
        ".#.",
        "###",
        ".#.",
    },
    &.{
        "..#",
        "..#",
        "###",
    },
    &.{
        "#",
        "#",
        "#",
        "#",
    },
    &.{
        "##",
        "##",
    },
};

fn overlaps(matrix: *utils.HashMatrix, rock: []const []const u8, left_pos: i32, height: i32) bool {
    if (height <= 0) return true;
    const delta_height = @as(i32, @intCast(rock.len)) + height - 1;
    for (rock, 0..) |row, i| {
        for (row, 0..) |col, j| {
            if (col == '.') continue;
            if (matrix.get(delta_height - @as(i32, @intCast(i)), left_pos + @as(i32, @intCast(j))) == '#')
                return true;
        }
    }
    return false;
}

fn part1(alloc: Allocator, data: []const u8) !void {
    var matrix = utils.HashMatrix.init(alloc);
    defer matrix.deinit();

    var rocks_iter = utils.Repeat([]const []const u8).init(&rocks);
    var input_iter = utils.Repeat(u8).init(data);

    const WIDTH = 7;
    const OFFSET_LEFT = 2;
    const OFFSET_DOWN = 3;
    var max_height: i32 = 0;

    std.debug.print("{s}\n", .{data});
    for (0..3) |_| {
        const rock = rocks_iter.next();
        var rock_height: i32 = max_height + OFFSET_DOWN;
        var rock_left_pos: i32 = OFFSET_LEFT;
        std.debug.print("S: Left {d}, Height {d}\n", .{ rock_left_pos, rock_height });
        while (true) {
            rock_left_pos += switch (input_iter.next()) {
                '>' => if (@as(i32, @intCast(rock[0].len)) + rock_left_pos < WIDTH) 1 else 0,
                else => if (rock_left_pos > 0) -1 else 0,
            };

            std.debug.print("Left {d}, Height {d}\n", .{ rock_left_pos, rock_height });
            if (overlaps(&matrix, rock, rock_left_pos, rock_height)) {
                for (0..rock.len) |i| {
                    for (0..rock[0].len) |j| {
                        if (rock[i][j] != '#') continue;
                        try matrix.set(rock_height + @as(i32, @intCast(rock.len - i)), rock_left_pos + @as(i32, @intCast(j)), '#');
                    }
                }
                max_height = rock_height + rock_height - 1;
                break;
            }
            rock_height -= 1;
        }

        for (0..20) |i| {
            const ii = 20 - i;
            for (0..WIDTH) |j| {
                const c: u8 = if (matrix.contains(@intCast(ii), @intCast(j))) '#' else '.';
                std.debug.print("{c}", .{c});
            }
            std.debug.print("\n", .{});
        }
    }

    // for (0..5) |_| {
    //     std.debug.print("{any},{d}\n", .{ rocks_iter.next(), input_iter.next() });
    // }

    //
}
