const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const PriorityQueue = std.PriorityQueue;
const time = std.time;
const Allocator = std.mem.Allocator;

const CT = i16;
const Point = struct {
    row: CT,
    col: CT,

    const Self = @This();

    fn init(row: CT, col: CT) Self {
        return .{ .row = row, .col = col };
    }
    fn initA(arr: [2]CT) Self {
        return .{ .row = arr[0], .col = arr[1] };
    }
    fn cast(self: Self) [2]u16 {
        return .{ @intCast(self.row), @intCast(self.col) };
    }
    fn eq(self: Self, o: Point) bool {
        return self.row == o.row and self.col == o.col;
    }
    fn addA(self: *Self, arr: [2]CT) Point {
        return .{
            .row = self.row + arr[0],
            .col = self.col + arr[1],
        };
    }
};

const State = struct {
    count: u32,
    pos: Point,
    dir: Point,

    const Self = @This();

    fn cmp(_: void, a: Self, b: Self) std.math.Order {
        if (a.count < b.count) return .lt;
        if (a.count > b.count) return .gt;
        return .eq;
    }
};

fn dijkstra(allocator: Allocator, matrix: []const []const u8, start_state: State) !u32 {
    var pqueue = PriorityQueue(State, void, State.cmp).init(allocator, undefined);
    defer pqueue.deinit();

    var visited = try myf.initValueMatrix(allocator, matrix.len, matrix[0].len, false);
    defer myf.freeMatrix(allocator, visited);

    try pqueue.add(start_state);
    while (pqueue.items.len != 0) {
        var state = pqueue.remove();

        const row, const col = state.pos.cast();
        if (matrix[row][col] == 'E') return state.count;

        if (visited[row][col]) continue;
        visited[row][col] = true;

        for (myf.getNeighborOffset(CT)) |next_dir| {
            const next_pos = state.pos.addA(next_dir);
            const next_row, const next_col = next_pos.cast();
            if (matrix[next_row][next_col] == '#') continue;

            const new_dir = Point.initA(next_dir);
            var new_cost = state.count + 1;
            if (!new_dir.eq(state.dir)) new_cost += 1000;

            try pqueue.add(.{
                .count = new_cost,
                .pos = next_pos,
                .dir = new_dir,
            });
        }
    }
    unreachable;
}

fn part2(allocator: Allocator, matrix: []const []const u8, start_state: State, min_value: u32) !u32 {
    var pqueue = PriorityQueue(State, void, State.cmp).init(allocator, undefined);
    defer pqueue.deinit();

    var visited = try myf.initValueMatrix(allocator, matrix.len, matrix[0].len, false);
    defer myf.freeMatrix(allocator, visited);

    var visited_nodes: u32 = 0;

    try pqueue.add(start_state);
    while (pqueue.items.len != 0) {
        var state = pqueue.remove();

        const row, const col = state.pos.cast();
        if (visited[row][col]) continue;
        visited[row][col] = true;
        visited_nodes += 1;

        for (myf.getNeighborOffset(CT)) |next_dir| {
            const next_pos = state.pos.addA(next_dir);
            const next_row, const next_col = next_pos.cast();
            if (matrix[next_row][next_col] == '#') continue;

            const new_dir = Point.initA(next_dir);
            var new_cost = state.count + 1;
            if (!new_dir.eq(state.dir)) new_cost += 1000;

            const next_state: State = .{
                .count = new_cost,
                .pos = next_pos,
                .dir = new_dir,
            };
            if (try dijkstra(allocator, matrix, next_state) <= min_value)
                try pqueue.add(next_state);
        }
    }
    return visited_nodes;
}

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);

    const matrix = try allocator.alloc([]const u8, input_attributes.row_len);
    defer allocator.free(matrix);

    var grid_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    for (matrix) |*row| row.* = grid_iter.next().?;

    const mat = try myf.initValueMatrix(allocator, 10, 10, false);
    defer myf.freeMatrix(allocator, mat);

    const start_state: State = .{
        .count = 0,
        .pos = Point.init(@intCast(matrix.len - 2), 1),
        .dir = Point.init(0, 1),
    };

    const p1_value = try dijkstra(allocator, matrix, start_state);
    try writer.print(
        "Part 1: {d}\nPart 2: {d}\n",
        .{ p1_value, try part2(allocator, matrix, start_state, p1_value) },
    );
}
