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

const VisitedT = std.ArrayHashMap(ComplexT, u32, HashCtx, true);
const SetT = std.ArrayHashMap(ComplexT, void, HashCtx, true);
const HashPathT = std.ArrayHashMap(ComplexT, std.ArrayList(ComplexT), HashCtx, true);
const rotations = [3]ComplexT{ ComplexT.init(1, 0), rot_left, rot_right };
const State = struct {
    count: u32,
    pos: ComplexT,
    dir: ComplexT,
    steps: u32,

    const Self = @This();

    fn cmp(_: void, a: Self, b: Self) std.math.Order {
        if (a.count < b.count) return .lt;
        if (a.count > b.count) return .gt;
        return .eq;
    }
};

const PathState = struct {
    cost: u32,
    pos: ComplexT,
    dir: ComplexT,
    path: SetT,
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

    const input = @embedFile("in/d16.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const matrix = try allocator.alloc([]const u8, input_attributes.row_len);
    defer allocator.free(matrix);

    var grid_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    for (matrix) |*row| row.* = grid_iter.next().?;

    const mat = try myf.initValueMatrix(allocator, 10, 10, false);
    defer myf.freeMatrix(allocator, mat);

    var pqueue = PriorityQueue(State, void, State.cmp).init(allocator, undefined);
    defer pqueue.deinit();
    try pqueue.add(.{
        .count = 0,
        .pos = ComplexT{ .re = @intCast(matrix.len - 2), .im = 1 },
        .dir = ComplexT{ .re = 0, .im = 1 }, // Facing east
        .steps = 0,
    });

    var all_paths = HashPathT.init(allocator);
    defer {
        for (all_paths.values()) |r| r.deinit();
        all_paths.deinit();
    }

    var visited = VisitedT.init(allocator);
    defer visited.deinit();
    var distances = VisitedT.init(allocator);
    defer distances.deinit();

    var min_distance: u32 = std.math.maxInt(u32);
    while (pqueue.items.len != 0) {
        var state = pqueue.remove();

        if (finishSymbol(matrix, state.pos, 'E')) {
            min_distance = distances.get(state.pos).?;
            break;
        }
        if (visited.get(state.pos) != null) continue;
        try visited.put(state.pos, 0);

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
                    .steps = state.steps + 1,
                });
            }
        }
    }
    printa(min_distance);

    var paths = std.ArrayList(SetT).init(allocator);
    defer {
        for (paths.items) |*r| r.*.deinit();
        defer paths.deinit();
    }

    var stack = std.ArrayList(PathState).init(allocator);
    defer stack.deinit();
    try stack.append(
        .{
            .cost = 0,
            .dir = ComplexT.init(0, 1),
            .pos = .{ .re = @intCast(matrix.len - 2), .im = 1 },
            .path = SetT.init(allocator),
        },
    );

    const end_pos = ComplexT{ .re = 1, .im = @intCast(matrix.len - 2) };

    while (stack.items.len != 0) {
        var state = stack.pop();
        defer state.path.deinit();

        if (eql(state.pos, end_pos)) {
            if (state.cost == min_distance) {
                try state.path.put(end_pos, {});
                try paths.append(try state.path.clone());
            }
            continue;
        }

        if (state.path.contains(state.pos)) continue;
        try state.path.put(state.pos, {});

        for (rotations, 0..) |rot, i| {
            const new_rotation = state.dir.mul(rot);
            const next_step = state.pos.add(new_rotation);
            if (!inBounds(matrix, next_step)) continue;
            if (state.path.contains(next_step)) continue;

            var new_cost: u32 = if (i == 0) 0 else 1000;
            new_cost += state.cost + 1;

            if (new_cost <= min_distance) {
                try stack.append(.{
                    .cost = new_cost,
                    .pos = next_step,
                    .path = try state.path.clone(),
                    .dir = new_rotation,
                });
            }
        }
    }

    var all_grids = SetT.init(allocator);
    defer all_grids.deinit();

    for (paths.items) |set| {
        for (set.keys()) |k| {
            try all_grids.put(k, {});
        }
    }
    printa(all_grids.count());
}

fn printCostMap(alloc: Allocator, matrix: []const []const u8, visited: VisitedT) void {
    // var new_matrix = myf.copyMatrix(alloc, matrix) catch unreachable;
    var new_matrix = myf.initValueMatrix(alloc, matrix.len, matrix[0].len, @as(u32, 0)) catch unreachable;
    defer myf.freeMatrix(alloc, new_matrix);

    for (visited.keys()) |key| {
        const row, const col = complexToUInt(key);
        new_matrix[row][col] = visited.get(key).?;
    }

    const stdout = std.io.getStdOut().writer();

    for (new_matrix) |row| {
        for (row) |e| {
            if (e == 0) {
                stdout.print("#     ", .{}) catch unreachable;
            } else {
                const digits = std.math.log10_int(e);
                switch (digits) {
                    0 => stdout.print("{d}     ", .{e}) catch unreachable,
                    1 => stdout.print("{d}    ", .{e}) catch unreachable,
                    2 => stdout.print("{d}   ", .{e}) catch unreachable,
                    3 => stdout.print("{d}  ", .{e}) catch unreachable,
                    4 => stdout.print("{d} ", .{e}) catch unreachable,
                    5 => stdout.print("{d}", .{e}) catch unreachable,
                    6 => stdout.print("{d}", .{e}) catch unreachable,
                    7 => stdout.print("{d}", .{e}) catch unreachable,
                    else => {},
                }
            }
        }
        stdout.print("\n", .{}) catch unreachable;
    }
}

fn printSitMap(alloc: Allocator, matrix: []const []const u8, visited: anytype) void {
    // var new_matrix = myf.copyMatrix(alloc, matrix) catch unreachable;
    var new_matrix = myf.initValueMatrix(alloc, matrix.len, matrix[0].len, @as(u8, '.')) catch unreachable;
    defer myf.freeMatrix(alloc, new_matrix);

    for (visited.keys()) |key| {
        const row, const col = complexToUInt(key);
        new_matrix[row][col] = 'O';
    }

    myf.printMatStr(new_matrix);
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
