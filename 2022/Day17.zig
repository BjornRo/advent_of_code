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

    const data = try utils.read(alloc, "in/d17.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var grid = Grid.init(alloc);
    defer grid.deinit();

    var cycle_detect: std.AutoHashMap(struct { usize, usize, u7 }, usize) = .init(alloc);
    defer cycle_detect.deinit();
    var cycle_len: usize = 0;
    var start_cycle: ?usize = null;

    var memo: std.AutoHashMap(usize, struct { sum: usize, delta: usize }) = .init(alloc);
    defer memo.deinit();
    var rocks_iter = utils.Repeat([]const []const u8).init(&rocks);
    var input_iter = utils.Repeat(u8).init(data);
    var last_max: i32 = 0;
    var max_height: i32 = 0;
    for (0..5000) |k| {
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
        try memo.put(k, .{ .sum = @intCast(max_height), .delta = @intCast(max_height - last_max) });

        var surf = std.bit_set.IntegerBitSet(7).initEmpty();
        for (0..7) |i| if (grid.get(max_height, @intCast(i)) != null) surf.set(i);
        const res = try cycle_detect.getOrPut(.{ rocks_iter.index, input_iter.index, @truncate(surf.mask) });
        if (start_cycle == null and res.found_existing) {
            const new_cycle = k - res.value_ptr.*;
            if (cycle_len == new_cycle) start_cycle = k else cycle_len = new_cycle;
        } else res.value_ptr.* = k;
    }
    const k = start_cycle.?;
    const remaining = 1000000000000 - k;
    const cycles = remaining / cycle_len;
    const left = remaining % cycle_len;

    var total_rocks = cycles * (memo.get(k + cycle_len).?.sum - memo.get(k).?.sum) + memo.get(k - 1).?.sum;
    for (0..left) |f| total_rocks += memo.get(f + k).?.delta;
    return .{ .p1 = memo.get(2021).?.sum, .p2 = total_rocks };
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
