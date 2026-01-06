const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const Point = struct { u16, u16 };
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

    const data = try utils.read(alloc, "in/d12.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.@"0"});
    std.debug.print("Part 2: {d}\n", .{result.@"1"});
}
fn solve(alloc: Allocator, data: []u8) !Point {
    var matrix = utils.arrayToMatrix(data);
    var start: Point = .{ std.math.maxInt(@typeInfo(Point).@"struct".fields[0].type), 0 };
    var end: Point = start;
    for (0..matrix.rows) |i| for (0..matrix.cols) |j| {
        const elem = matrix.get(i, j);
        if (elem == 'E') {
            start = .{ @truncate(i), @truncate(j) };
            matrix.set(i, j, 'z');
        } else if (elem == 'S') {
            end = .{ @truncate(i), @truncate(j) };
            matrix.set(i, j, 'a');
        }
    };
    return try dfs(alloc, &matrix, start, end);
}
fn dfs(alloc: Allocator, matrix: *utils.Matrix, start: Point, end: Point) !Point {
    var queue = try Deque(struct { count: u16, pos: Point, state: u8 }).init(alloc);
    defer queue.deinit();

    var min_S: @typeInfo(Point).@"struct".fields[0].type = std.math.maxInt(@typeInfo(Point).@"struct".fields[0].type);
    var min_a = min_S;
    try queue.pushBack(.{ .count = 0, .pos = start, .state = 'z' });
    while (queue.popFront()) |state| {
        var tile = matrix.get(state.pos.@"0", state.pos.@"1");
        if (std.meta.eql(state.pos, end) and state.count < min_S) {
            min_S = state.count;
            break;
        } else if (tile & 0x7F == 'a' and state.count < min_a) {
            min_a = state.count;
        }
        if (tile & 0x80 != 0) continue;
        matrix.set(state.pos.@"0", state.pos.@"1", tile | 0x80);

        for (utils.getNextPositions(@as(i32, @intCast(state.pos.@"0")), @as(i32, @intCast(state.pos.@"1")))) |next| {
            if (!matrix.inBounds(next[0], next[1])) continue;
            const dp: Point = .{ @intCast(next[0]), @intCast(next[1]) };
            tile = matrix.get(dp.@"0", dp.@"1") & 0x7F;
            if (tile >= state.state - 1) try queue.pushBack(.{ .count = state.count + 1, .pos = dp, .state = tile });
        }
    }
    return .{ min_a, min_S };
}
