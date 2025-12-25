const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const Point = struct { usize, usize };
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d12.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.@"0"});
    std.debug.print("Part 2: {d}\n", .{result.@"1"});
}
fn solve(alloc: Allocator, data: []u8) !Point {
    var matrix = utils.arrayToMatrix(data);
    var start: Point = undefined;
    var end: Point = undefined;
    for (0..matrix.rows) |i| for (0..matrix.cols) |j| {
        const elem = matrix.get(i, j);
        if (elem == 'E') {
            start = .{ i, j };
            matrix.set(i, j, 'z');
        } else if (elem == 'S') {
            end = .{ i, j };
            matrix.set(i, j, 'a');
        }
    };
    return try dfs(alloc, &matrix, start, end);
}
fn dfs(alloc: Allocator, matrix: *utils.Matrix, start: Point, end: Point) !Point {
    const State = struct { count: usize, pos: Point, state: u8 };

    var queue = try Deque(State).init(alloc);
    defer queue.deinit();

    var min_S: usize = 1 << 31;
    var min_a: usize = 1 << 31;
    try queue.pushBack(.{ .count = 0, .pos = start, .state = 'z' });
    while (queue.popFront()) |state| {
        const row, const col = state.pos;
        const tile = matrix.get(row, col);
        if (std.meta.eql(state.pos, end) and state.count < min_S) {
            min_S = state.count;
        } else if (tile & 0x7F == 'a' and state.count < min_a) {
            min_a = state.count;
        }
        if (tile & 0x80 != 0) continue;
        matrix.set(row, col, tile | 0x80);

        for (utils.getNextPositions(@as(i32, @intCast(row)), @as(i32, @intCast(col)))) |next| {
            const dr, const dc = next;
            if (!matrix.inBounds(dr, dc)) continue;
            const elem = matrix.get(@intCast(dr), @intCast(dc)) & 0x7F;
            if (elem >= state.state - 1)
                try queue.pushBack(.{ .count = state.count + 1, .pos = .{ @intCast(dr), @intCast(dc) }, .state = elem });
        }
    }
    return .{ min_a, min_S };
}
