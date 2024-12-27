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
    fn toArr(self: Self) [2]CT {
        return .{ self.row, self.col };
    }
    fn addA(self: Self, arr: [2]CT) Point {
        return .{
            .row = self.row + arr[0],
            .col = self.col + arr[1],
        };
    }
};

const HashCtx = struct {
    pub fn hash(_: @This(), key: Point) u64 {
        return @bitCast([4]CT{ key.row, 0, key.col, 0 });
    }
    pub fn eql(_: @This(), a: Point, b: Point) bool {
        return a.eq(b);
    }
};

const DistanceMap = std.HashMap(Point, i32, HashCtx, 80);
const Set = std.HashMap(Point, void, HashCtx, 80);
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

    var min_value = try dijkstra(allocator, matrix, .{
        .count = 0,
        .pos = Point.init(@intCast(matrix.len - 2), 1),
        .dir = Point.init(0, 1),
    });
    defer min_value.map.deinit();

    printa(min_value.min_steps);
    const res = try part2(allocator, matrix, Point.init(1, @intCast(matrix.len - 2)), min_value.map);
    printa(res);
}

fn part2(allocator: Allocator, start_pos: Point, map: DistanceMap) !?Set {
    var stack = std.ArrayList(Point).init(allocator);
    defer stack.deinit();
    try stack.append(start_pos);

    var visited = Set.init(allocator);

    while (stack.items.len != 0) {
        var position = stack.pop();

        if (visited.get(position) != null) continue;
        try visited.put(position, {});

        const current_cost = map.get(position).?;
        for (myf.getNeighborOffset(CT)) |next_dir| {
            const next_pos = position.addA(next_dir);
            if (map.get(next_pos)) |value| {
                const diff = current_cost - value;
                printa(current_cost);
                if (diff == 1 or diff == 1001) try stack.append(next_pos);
            }
        }
    }
    return visited;
}

fn printPath(allocator: Allocator, matrix: []const []const u8, map: Set) !void {
    var mat = try myf.initValueMatrix(allocator, matrix.len, matrix[0].len, @as(u8, '.'));
    defer myf.freeMatrix(allocator, mat);

    var kit = map.keyIterator();
    while (kit.next()) |pos| {
        const row, const col = pos.cast();
        mat[row][col] = 'O';
    }
    for (mat) |r| {
        prints(r);
    }
}

fn dijkstra(allocator: Allocator, matrix: []const []const u8, start_state: State) !struct { min_steps: u32, map: DistanceMap } {
    var pqueue = PriorityQueue(State, void, State.cmp).init(allocator, undefined);
    defer pqueue.deinit();

    var visited = try myf.initValueMatrix(allocator, matrix.len, matrix[0].len, false);
    defer myf.freeMatrix(allocator, visited);

    var distances = DistanceMap.init(allocator);
    try distances.put(start_state.pos, 0);

    try pqueue.add(start_state);
    while (pqueue.items.len != 0) {
        var state = pqueue.remove();

        const row, const col = state.pos.cast();
        if (matrix[row][col] == 'E') {
            return .{ .min_steps = state.count, .map = distances };
        }

        if (visited[row][col]) continue;
        visited[row][col] = true;

        for (myf.getNeighborOffset(CT)) |next_dir| {
            const next_pos = state.pos.addA(next_dir);
            const next_row, const next_col = next_pos.cast();
            if (matrix[next_row][next_col] == '#') continue;

            const new_dir = Point.initA(next_dir);
            var new_cost = state.count + 1;
            if (!new_dir.eq(state.dir)) new_cost += 1000;

            if (new_cost < distances.get(next_pos) orelse std.math.maxInt(i32)) {
                try distances.put(next_pos, @intCast(new_cost));
                try pqueue.add(.{
                    .count = new_cost,
                    .pos = next_pos,
                    .dir = new_dir,
                });
            }
        }
    }
    unreachable;
}
