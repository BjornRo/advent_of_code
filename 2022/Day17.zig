const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

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
    if (height < 0) return true;
    const delta = rock.len + @as(usize, @intCast(height));
    for (rock, 0..) |row, i| for (row, @intCast(left_pos)..) |col, j|
        if (col == '#' and grid.get(@intCast(delta - i), @intCast(j)) == '#') return true;
    return false;
}

fn part1(alloc: Allocator, data: []const u8) !void {
    var grid = Grid.init(alloc);
    defer grid.deinit();

    var rocks_iter = utils.Repeat([]const []const u8).init(&rocks);
    var input_iter = utils.Repeat(u8).init(data);

    var max_height: i32 = 0;
    for (0..2022) |_| {
        const rock = rocks_iter.next();
        var height: i32 = max_height + 3;
        var left_pos: i8 = 2;
        while (true) {
            const res: i8 = switch (input_iter.next()) {
                '>' => if (@as(i8, @intCast(rock[0].len)) + left_pos < 7) 1 else 0,
                else => if (left_pos > 0) -1 else 0,
            };
            if (!overlaps(&grid, rock, left_pos + res, height)) left_pos += res;
            if (overlaps(&grid, rock, left_pos, height - 1)) {
                const delta = rock.len + @as(usize, @intCast(height));
                for (0..rock.len) |i| for (0..rock[0].len) |j| {
                    if (rock[i][j] == '#') try grid.set(@intCast(delta - i), left_pos + @as(i8, @intCast(j)), '#');
                };
                max_height = @max(max_height, height + @as(i32, @intCast(rock.len)));
                break;
            }
            height -= 1;
        }
    }
    std.debug.print("{d}\n", .{max_height});
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
