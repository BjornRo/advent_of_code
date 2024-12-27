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
const ComplexT = std.math.Complex(CT);
const rot_right = ComplexT.init(0, -1);
const rot_left = ComplexT.init(0, 1);

const HashCtx = struct {
    pub fn hash(_: @This(), key: ComplexT) u32 {
        return @bitCast([2]CT{ key.re, key.im });
    }
    pub fn eql(_: @This(), a: ComplexT, b: ComplexT, _: usize) bool {
        return a.re == b.re and a.im == b.im;
    }
};

const DistanceMap = std.ArrayHashMap(ComplexT, u32, HashCtx, true);
const Set = std.ArrayHashMap(ComplexT, void, HashCtx, true);
const rotations = [3]ComplexT{ ComplexT.init(1, 0), rot_left, rot_right };
const State = struct {
    count: u32,
    pos: ComplexT,
    dir: ComplexT,

    const Self = @This();

    fn cmp(_: void, a: Self, b: Self) std.math.Order {
        if (a.count < b.count) return .lt;
        if (a.count > b.count) return .gt;
        return .eq;
    }
};

fn complexToUInt(c: ComplexT) [2]u16 {
    return .{ @bitCast(c.re), @bitCast(c.im) };
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

    const min_value = try dijkstra(allocator, matrix, .{
        .count = 0,
        .pos = ComplexT{ .re = @intCast(matrix.len - 2), .im = 1 },
        .dir = ComplexT{ .re = 0, .im = 1 }, // Facing east
    });

    printa(min_value);
    // const res = try part2(allocator, matrix, .{
    //     .count = 0,
    //     .pos = ComplexT{ .re = @intCast(matrix.len - 2), .im = 1 },
    //     .dir = ComplexT{ .re = 0, .im = 1 }, // Facing east
    // }, min_value);
    // printa(res);
}

fn part2(allocator: Allocator, matrix: []const []const u8, curr_state: State, min_value: u32) !u32 {
    var pqueue = PriorityQueue(State, void, State.cmp).init(allocator, undefined);
    defer pqueue.deinit();
    try pqueue.add(curr_state);

    var all_positions = Set.init(allocator);
    defer all_positions.deinit();

    var visited = Set.init(allocator);
    defer visited.deinit();

    while (pqueue.items.len != 0) {
        var state = pqueue.remove();
        try all_positions.put(state.pos, {});

        if (finishSymbol(matrix, state.pos, 'E')) continue;
        if (visited.get(state.pos) != null) continue;
        try visited.put(state.pos, {});

        for (rotations, 0..) |rot, i| {
            const new_rotation = state.dir.mul(rot);
            const next_step = state.pos.add(new_rotation);
            if (!inBounds(matrix, next_step)) continue;

            var new_cost: u32 = if (i == 0) 0 else 1000;
            new_cost += state.count + 1;

            const next_state = State{
                .count = new_cost,
                .pos = next_step,
                .dir = new_rotation,
            };

            const res = try dijkstra(allocator, matrix, next_state);
            if (res == std.math.maxInt(u32)) continue;

            if (res <= min_value) {
                try pqueue.add(next_state);
            }
        }
    }
    return @intCast(all_positions.count());
}

fn dijkstra(allocator: Allocator, matrix: []const []const u8, curr_state: State) !u32 {
    var pqueue = PriorityQueue(State, void, State.cmp).init(allocator, undefined);
    defer pqueue.deinit();
    try pqueue.add(curr_state);

    var visited = Set.init(allocator);
    defer visited.deinit();
    var distances = DistanceMap.init(allocator);
    defer distances.deinit();

    var min_distance: u32 = std.math.maxInt(u32);
    while (pqueue.items.len != 0) {
        var state = pqueue.remove();

        if (finishSymbol(matrix, state.pos, 'E')) {
            min_distance = state.count;
            break;
        }
        if (visited.get(state.pos) != null) continue;
        try visited.put(state.pos, {});

        for (rotations, 0..) |rot, i| {
            const new_rotation = state.dir.mul(rot);
            const next_step = state.pos.add(new_rotation);
            if (!inBounds(matrix, next_step)) continue;

            var new_cost: u32 = if (i == 0) 0 else 1000;
            new_cost += state.count + 1;

            const next_cost = distances.get(next_step) orelse std.math.maxInt(u32);

            if (new_cost < next_cost) {
                try distances.put(next_step, new_cost);
                try pqueue.add(.{
                    .count = new_cost,
                    .pos = next_step,
                    .dir = new_rotation,
                });
            }
        }
    }
    return min_distance;
}

fn inBounds(matrix: []const []const u8, complex: ComplexT) bool {
    const row, const col = complexToUInt(complex);
    return matrix[row][col] != '#';
}

fn finishSymbol(matrix: []const []const u8, complex: ComplexT, scalar: u8) bool {
    const row, const col = complexToUInt(complex);
    return matrix[row][col] == scalar;
}

pub fn eql(a: ComplexT, b: ComplexT) bool {
    return a.re == b.re and a.im == b.im;
}
