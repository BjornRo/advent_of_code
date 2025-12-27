const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const Grid = utils.HashMatrix;
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d17.txt");
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

fn overlaps(grid: *Grid, rock: []const []const u8, left_pos: i32, height: i32) bool {
    const delta_height = @as(i32, @intCast(rock.len)) + height;
    for (rock, 0..) |row, i| {
        for (row, 0..) |col, j| {
            if (col != '#') continue;
            if (grid.get(delta_height - @as(i32, @intCast(i)), left_pos + @as(i32, @intCast(j))) == '#')
                return true;
        }
    }
    return false;
}

fn part1(alloc: Allocator, data: []const u8) !void {
    var grid = Grid.init(alloc);
    defer grid.deinit();

    var rocks_iter = utils.Repeat([]const []const u8).init(&rocks);
    var input_iter = utils.Repeat(u8).init(data);

    const WIDTH = 7;
    const OFFSET_LEFT = 2;
    const OFFSET_DOWN = 3;
    var max_height: i32 = 0;

    for (0..2022) |_| {
        const rock = rocks_iter.next();
        var height: i32 = max_height + OFFSET_DOWN;
        var left_pos: i32 = OFFSET_LEFT;
        // std.debug.print("S: Left {d}, Height {d}\n", .{ left_pos, height });
        while (true) {
            // >>>< <><> ><<< >><>>><<<>>><<<><<<>><>><<>>
            const res: i8 = switch (input_iter.next()) {
                '>' => if (@as(i32, @intCast(rock[0].len)) + left_pos < WIDTH) 1 else 0,
                else => if (left_pos > 0) -1 else 0,
            };

            if (!overlaps(&grid, rock, left_pos + res, height)) left_pos += res;

            // std.debug.print("Left {d}, Height {d}\n", .{ left_pos, height });
            if (overlaps(&grid, rock, left_pos, height - 1) or height - 1 < 0) {
                try fill(&grid, rock, height, left_pos);
                max_height = @max(max_height, height + @as(i32, @intCast(rock.len)));
                // std.debug.print("MH {d}\n", .{max_height});
                break;
            }
            height -= 1;
        }
        // p(&grid);
    }
    std.debug.print("{d}\n", .{max_height});

    // for (0..5) |_| {
    //     std.debug.print("{any},{d}\n", .{ rocks_iter.next(), input_iter.next() });
    // }

    //
}

fn fill(grid: *Grid, rock: []const []const u8, height_pos: i32, left_pos: i32) !void {
    for (0..rock.len) |i| for (0..rock[0].len) |j| {
        if (rock[i][j] != '#') continue;
        try grid.set(height_pos + @as(i32, @intCast(rock.len - i)), left_pos + @as(i32, @intCast(j)), '#');
    };
}

fn p(m: *Grid) void {
    const h = 30;
    for (0..h) |i| {
        const ii = h - i;
        for (0..7) |j| {
            const c: u8 = if (m.get(@intCast(ii), @intCast(j))) |v| v else ',';
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }
}
