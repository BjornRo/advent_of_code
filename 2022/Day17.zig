const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const Grid = utils.HashMatrix;
const rocks: [5][]const []const u8 = .{
    &.{"####"},
    &.{ ".#.", "###", ".#." },
    &.{ "..#", "..#", "###" },
    &.{ "#", "#", "#", "#" },
    &.{ "##", "##" },
};
fn overlaps(grid: *Grid, rock: []const []const u8, left_pos: i32, height: i32) bool {
    if (height < 0) return true;
    const delta = rock.len + @as(usize, @intCast(height));
    for (rock, 0..) |row, i| for (row, @intCast(left_pos)..) |col, j|
        if (col == '#' and grid.get(@intCast(delta - i), @intCast(j)) == '#') return true;
    return false;
}

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d17t.txt");
    defer alloc.free(data);

    // std.debug.print("Part 1: {d}\n", .{try part1(alloc, data, 2022)});
    std.debug.print("Part 2: {d}\n", .{try part2(alloc, data, 5000)});
}

fn part2(alloc: Allocator, data: []const u8, n_rocks: usize) !i32 {
    var grid = Grid.init(alloc);
    defer grid.deinit();
    var rocks_iter = utils.Repeat([]const []const u8).init(&rocks);
    var input_iter = utils.Repeat(u8).init(data);

    var map: std.AutoHashMap(struct { usize, usize, u7 }, usize) = .init(alloc);
    defer map.deinit();
    var memo: std.AutoHashMap(usize, usize) = .init(alloc);
    defer memo.deinit();
    var memo2: std.AutoHashMap(usize, usize) = .init(alloc);
    defer memo2.deinit();
    var cycle_len: usize = 0;

    var last_max: i32 = 0;
    var w: ?usize = null;

    var max_height: i32 = 0;
    for (0..n_rocks) |k| {
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
                last_max = max_height;
                max_height = @max(max_height, height + @as(i32, @intCast(rock.len)));
                break;
            }
            height -= 1;
        }
        try memo.put(k, @intCast(max_height));
        try memo2.put(k, @intCast(max_height - last_max));
        var surf = std.bit_set.IntegerBitSet(7).initEmpty();
        for (0..7) |i| if (grid.get(max_height, @intCast(i)) != null) surf.set(i);
        const res = try map.getOrPut(.{ rocks_iter.index, input_iter.index, @truncate(surf.mask) });
        if (res.found_existing) {
            const new_cycle = k - res.value_ptr.*;
            if (cycle_len == new_cycle) {
                if (w == null) w = k;
            } else {
                cycle_len = new_cycle;
            }
            res.value_ptr.* = k;
        } else {
            res.value_ptr.* = k;
        }
    }
    // too high 1540634005753 1540634005752
    // too low  1528901734094
    std.debug.print("{d}\n", .{cycle_len});
    const l = w.? + 3;
    const remaining = 1000000000000 - l;
    const cycles = remaining / cycle_len;
    const left = remaining % cycle_len;

    var total_rocks = cycles * (memo.get(l + cycle_len).? - memo.get(l).?) + memo.get(l).?;
    for (0..left) |f| {
        total_rocks += memo2.get(f + l).?;
    }
    std.debug.print("{d}\n", .{total_rocks});

    return max_height;
}
// std.debug.print("{d} {d}\n", .{ rocks_iter.index, input_iter.index });
// std.debug.print("{d} {d}\n", .{ res.value_ptr.*, k });
// std.debug.print("{d}\n", .{memo.get(k).?});
// std.debug.print("{d}\n", .{memo.get(k - cycle_len).?});
// (memo.get(k - cycle_len).? - memo.get(k).?);
// const c = res.value_ptr.*;
// std.debug.print("{d}\n", .{new_cycle});
// std.debug.print("{d}\n", .{k});
fn part1(alloc: Allocator, data: []const u8, n_rocks: usize) !i32 {
    var grid = Grid.init(alloc);
    defer grid.deinit();
    var rocks_iter = utils.Repeat([]const []const u8).init(&rocks);
    var input_iter = utils.Repeat(u8).init(data);

    var max_height: i32 = 0;
    for (0..n_rocks) |_| {
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
    return max_height;
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
