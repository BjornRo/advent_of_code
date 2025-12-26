const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const Map = std.AutoArrayHashMap(Point, Point);
const Point = struct {
    row: i64,
    col: i64,
    const Self = @This();
    fn manhattan(self: Self, o: Self) i64 {
        return @intCast(self.deltaRow(o.row) + self.deltaCol(o.col));
    }
    fn deltaRow(self: Self, row: i64) i64 {
        return @intCast(@abs(self.row - row));
    }
    fn deltaCol(self: Self, col: i64) i64 {
        return @intCast(@abs(self.col - col));
    }
};
const Pair = struct { i64, i64 };
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d15.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: i64 } {
    var sensors: Map = .init(alloc);
    defer sensors.deinit();

    var split_iter = std.mem.splitScalar(u8, data, '\n');
    while (split_iter.next()) |item| {
        var row_iter = utils.NumberIter(i64){ .string = item };
        var col = row_iter.next().?;
        const sensor = Point{ .row = row_iter.next().?, .col = col };
        col = row_iter.next().?;
        try sensors.put(sensor, .{ .row = row_iter.next().?, .col = col });
    }
    return .{ .p1 = try part1(alloc, &sensors), .p2 = try part2(alloc, &sensors) };
}
fn part1(alloc: Allocator, sensors: *Map) !usize {
    var cols: std.AutoHashMap(i64, void) = .init(alloc);
    defer cols.deinit();

    const row: i64 = 2000000;
    var iter = sensors.iterator();
    while (iter.next()) |pair| {
        const sensor = pair.key_ptr;
        const beacon = pair.value_ptr;

        const distance = sensor.manhattan(beacon.*);
        const drow: i64 = sensor.deltaRow(row);
        if (drow > distance) continue;

        const delta = distance - drow;

        for (0..@intCast(delta * 2 + 1)) |i| {
            const val = sensor.col - delta + @as(i64, @intCast(i));
            if (beacon.row == row and beacon.col == val) continue;
            try cols.put(val, {});
        }
    }
    return cols.count();
}
fn part2(alloc: Allocator, sensors: *Map) !i64 {
    var intervals: std.ArrayList(Pair) = .empty;
    defer intervals.deinit(alloc);

    const max: i64 = 4000000;
    for (0..@intCast(max + 1)) |row| {
        intervals.clearRetainingCapacity();

        for (sensors.keys(), sensors.values()) |sensor, beacon| {
            const drow = sensor.deltaRow(@intCast(row));
            const distance = sensor.manhattan(beacon);
            if (drow > distance) continue;

            const delta = distance - drow;
            try intervals.append(alloc, .{
                @max(0, sensor.col - delta),
                @min(max, sensor.col + delta),
            });
        }
        const res = try mergeIntervals(alloc, intervals.items);
        defer alloc.free(res);
        if (res.len != 2 or res[1].@"0" - res[0].@"1" != 2) continue;
        const candidate_row = @divFloor(res[1].@"0" + res[0].@"1", 2);
        const irow: i64 = @intCast(row);
        if (isCovered(sensors, irow - 1, candidate_row) and isCovered(sensors, irow + 1, candidate_row))
            return irow + 4000000 * candidate_row;
    }
    return -1;
}
fn isCovered(sensors: *Map, row: i64, col: i64) bool {
    for (sensors.keys(), sensors.values()) |sensor, beacon| {
        const point_dist = sensor.manhattan(.{ .row = row, .col = col });
        if (point_dist == sensor.manhattan(beacon)) return true;
    }
    return false;
}
fn compare(_: void, lhs: Pair, rhs: Pair) bool {
    return lhs.@"0" < rhs.@"0";
}
fn mergeIntervals(alloc: Allocator, intervals: []Pair) ![]Pair {
    std.mem.sortUnstable(Pair, intervals, {}, compare);

    var merged: std.ArrayList(Pair) = .empty;
    defer merged.deinit(alloc);

    var current = intervals[0];
    for (intervals[1..]) |ival|
        if (ival.@"0" <= current.@"1" + 1) {
            current.@"1" = @max(current.@"1", ival.@"1");
        } else {
            try merged.append(alloc, current);
            current = ival;
        };
    try merged.append(alloc, current);
    return merged.toOwnedSlice(alloc);
}
