const std = @import("std");
const utils = @import("utils.zig");

const List = std.ArrayList(Point);
const Pairs = struct { Point, i32 };
const Point = struct {
    a: i32,
    b: i32,
    const Self = @This();
    inline fn manhattan(self: Self, o: Self) i32 {
        return self.deltaRow(o.a) + @as(i32, @intCast(@abs(self.b - o.b)));
    }
    inline fn deltaRow(self: Self, row: i32) i32 {
        return @intCast(@abs(self.a - row));
    }
    fn compare(_: void, lhs: Self, rhs: Self) bool {
        return lhs.a < rhs.a;
    }
};
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
fn solve(alloc: std.mem.Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var pairs: std.ArrayList(Pairs) = .empty;
    defer pairs.deinit(alloc);

    var split_iter = std.mem.splitScalar(u8, data, '\n');
    while (split_iter.next()) |item| {
        var row_iter = utils.NumberIter(i32){ .string = item };
        var col = row_iter.next().?;
        const sensor: Point = .{ .a = row_iter.next().?, .b = col };
        col = row_iter.next().?;
        try pairs.append(alloc, .{ sensor, sensor.manhattan(.{ .a = row_iter.next().?, .b = col }) });
    }
    var buffer: List = try .initCapacity(alloc, pairs.items.len);
    var intervals: List = try .initCapacity(alloc, pairs.items.len);
    defer buffer.deinit(alloc);
    defer intervals.deinit(alloc);
    return .{ .p1 = part1(pairs.items, &buffer, &intervals), .p2 = part2(pairs.items, &buffer, &intervals) };
}
inline fn genIntervals(pairs: []const Pairs, row: i32, buffer: *List, intervals: *List) void {
    buffer.clearRetainingCapacity();
    intervals.clearRetainingCapacity();
    for (pairs) |pair| {
        const delta = pair.@"1" - pair.@"0".deltaRow(row);
        if (0 <= delta) buffer.appendAssumeCapacity(.{ .a = pair.@"0".b - delta, .b = pair.@"0".b + delta });
    }
    std.mem.sort(Point, buffer.items, {}, Point.compare);
    var current = buffer.items[0];
    for (buffer.items[1..]) |ival|
        if (ival.a <= current.b + 1) {
            current.b = @max(current.b, ival.b);
        } else {
            intervals.appendAssumeCapacity(current);
            current = ival;
        };
    intervals.appendAssumeCapacity(current);
}
fn part1(pairs: []const Pairs, buffer: *List, intervals: *List) usize {
    genIntervals(pairs, 2_000_000, buffer, intervals);
    return @abs(intervals.items[0].b - intervals.items[0].a);
}
inline fn isCovered(pairs: []const Pairs, row: i32, col: i32) bool {
    const candidate: Point = .{ .a = row, .b = col };
    for (pairs) |pair| if (pair.@"0".manhattan(candidate) == pair.@"1") return true;
    return false;
}
fn part2(pairs: []const Pairs, buffer: *List, intervals: *List) usize {
    const max: i64 = 4_000_000;
    for (@intCast(@divFloor(max, 2))..@intCast(max + 1)) |row| { // change to 0.. for more correctness
        genIntervals(pairs, @intCast(row), buffer, intervals);
        if (intervals.items.len != 2 or intervals.items[1].a - intervals.items[0].b != 2) continue;
        const candidate_row = @divFloor(intervals.items[1].a + intervals.items[0].b, 2);
        const irow: i32 = @intCast(row);
        if (isCovered(pairs, irow - 1, candidate_row) and isCovered(pairs, irow + 1, candidate_row))
            return @intCast(irow + max * candidate_row);
    }
    return 0;
}
