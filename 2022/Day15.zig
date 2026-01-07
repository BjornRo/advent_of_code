const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const Points = struct { Point, Point };
const List = std.ArrayList(Points);
const Point = struct {
    row: i32,
    col: i32,
    const Self = @This();
    inline fn manhattan(self: Self, o: Self) i32 {
        return self.deltaRow(o.row) + @as(i32, @intCast(@abs(self.col - o.col)));
    }
    inline fn deltaRow(self: Self, row: i32) i32 {
        return @intCast(@abs(self.row - row));
    }
};
const Pair = struct { i32, i32 };
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const alloc, const is_debug = switch (@import("builtin").mode) {
        .Debug => .{ debug_allocator.allocator(), true },
        else => .{ std.heap.smp_allocator, false },
    };
    const start = std.time.microTimestamp();
    defer {
        std.debug.print("Time: {any}s\n", .{@as(f64, @floatFromInt(std.time.microTimestamp() - start)) / 1000_000});
        if (is_debug) _ = debug_allocator.deinit();
    }

    const data = try utils.read(alloc, "in/d15.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: i64 } {
    var pairs: List = .empty;
    defer pairs.deinit(alloc);

    var split_iter = std.mem.splitScalar(u8, data, '\n');
    while (split_iter.next()) |item| {
        var row_iter = utils.NumberIter(i32){ .string = item };
        var col = row_iter.next().?;
        const sensor = Point{ .row = row_iter.next().?, .col = col };
        col = row_iter.next().?;
        try pairs.append(alloc, .{ sensor, .{ .row = row_iter.next().?, .col = col } });
    }
    return .{ .p1 = try part1(alloc, pairs.items), .p2 = try part2(alloc, pairs.items) };
}
fn part1(alloc: Allocator, pairs: []Points) !usize {
    const H = struct {
        pub inline fn hash(_: @This(), k: u32) u64 {
            return utils.hashU64(k);
        }
        pub inline fn eql(_: @This(), a: u32, b: u32) bool {
            return a == b;
        }
    };
    var cols: std.HashMapUnmanaged(u32, void, H, 80) = .empty;
    defer cols.deinit(alloc);

    const row: i32 = 2000000;
    for (pairs) |pair| {
        const sensor, const beacon = pair;
        const distance = sensor.manhattan(beacon);
        const drow = sensor.deltaRow(row);
        if (drow > distance) continue;

        const delta = distance - drow;
        for (0..@intCast(delta * 2 + 1)) |i| {
            const val = sensor.col - delta + @as(i32, @intCast(i));
            if (beacon.row == row and beacon.col == val) continue;
            _ = try cols.getOrPut(alloc, @intCast(val));
        }
    }
    return cols.count();
}
fn part2(alloc: Allocator, pairs: []Points) !i64 {
    var intervals: std.ArrayList(Pair) = try .initCapacity(alloc, 20);
    var merged: std.ArrayList(Pair) = try .initCapacity(alloc, 20);
    defer intervals.deinit(alloc);
    defer merged.deinit(alloc);

    const max: i64 = 4000000;
    for (@intCast(@divFloor(max, 2))..@intCast(max + 1)) |row| {
        intervals.clearRetainingCapacity();
        merged.clearRetainingCapacity();

        for (pairs) |pair| {
            const sensor, const beacon = pair;
            const drow = sensor.deltaRow(@intCast(row));
            const distance = sensor.manhattan(beacon);
            if (drow > distance) continue;

            const delta = distance - drow;
            intervals.appendAssumeCapacity(.{ @max(0, sensor.col - delta), @min(max, sensor.col + delta) });
        }
        std.mem.sort(Pair, intervals.items, {}, compare);
        mergeIntervals(&merged, intervals.items);
        if (merged.items.len != 2 or merged.items[1].@"0" - merged.items[0].@"1" != 2) continue;
        const candidate_row = @divFloor(merged.items[1].@"0" + merged.items[0].@"1", 2);
        const irow: i32 = @intCast(row);
        if (isCovered(pairs, irow - 1, candidate_row) and isCovered(pairs, irow + 1, candidate_row))
            return irow + max * candidate_row;
    }
    return -1;
}
inline fn isCovered(pairs: []Points, row: i32, col: i32) bool {
    const candidate: Point = .{ .row = row, .col = col };
    for (pairs) |pair| if (pair.@"0".manhattan(candidate) == pair.@"0".manhattan(pair.@"1")) return true;
    return false;
}
fn compare(_: void, lhs: Pair, rhs: Pair) bool {
    return lhs.@"0" < rhs.@"0";
}
inline fn mergeIntervals(list: *std.ArrayList(Pair), intervals: []const Pair) void {
    var current = intervals[0];
    for (intervals[1..]) |ival|
        if (ival.@"0" <= current.@"1" + 1) {
            current.@"1" = @max(current.@"1", ival.@"1");
        } else {
            list.appendAssumeCapacity(current);
            current = ival;
        };
    list.appendAssumeCapacity(current);
}
