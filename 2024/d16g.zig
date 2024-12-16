const std = @import("std");
const myf = @import("mylib/myfunc.zig");
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

const Direction = enum { up, down, left, right };

const VisitedT = std.ArrayHashMap(ComplexT, u32, HashCtx, true);
const SetT = std.ArrayHashMap(ComplexT, void, HashCtx, true);
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
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    // std.debug.print("{s}\n", .{input});
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

    var visited = VisitedT.init(allocator);
    defer visited.deinit();
    var distances = VisitedT.init(allocator);
    defer distances.deinit();
    var steps = VisitedT.init(allocator);
    defer steps.deinit();
    var visited_crossings = VisitedT.init(allocator);
    defer visited_crossings.deinit();

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

            if (new_cost < distances.get(next_step) orelse std.math.maxInt(u32)) {
                const count = visited_crossings.get(next_step) orelse 0;
                try visited_crossings.put(next_step, count + 1);

                try steps.put(next_step, state.steps + 1);

                try distances.put(next_step, new_cost);
                try pqueue.add(.{
                    .count = new_cost,
                    .pos = next_step,
                    .dir = new_rotation,
                    .steps = state.steps + 1,
                });
            } else {
                const count = visited_crossings.get(next_step) orelse 0;
                try visited_crossings.put(next_step, count + 1);
            }
        }
    }
    printa(min_distance);

    // printa(distances.values());
    // for (distances.values()) |*v| v.* = @mod(v.*, 1000);
    // printa(distances.values());

    var sit_map = VisitedT.init(allocator);
    defer sit_map.deinit();
    try sit_map.put(.{ .re = @intCast(matrix.len - 2), .im = 1 }, 0);
    // dfs(
    //     allocator,
    //     .{ .re = 1, .im = @intCast(matrix.len - 2) },
    //     .{ .re = @intCast(matrix.len - 2), .im = 1 },
    //     steps,
    //     visited_crossings,
    //     &sit_map,
    // );

    // printa(steps.values());
    // printSitMap(allocator, matrix, sit_map);
    // printCostMap(allocator, matrix, distances);
    // printa(sit_map.keys().len);
    var graph = try matrixToGraph(allocator, matrix, .{ .re = @intCast(matrix.len - 2), .im = 1 }, .{ .re = 1, .im = @intCast(matrix.len - 2) });
    defer {
        for (graph.values()) |*gkeys| gkeys.*.deinit();
        graph.deinit();
    }
    // printSitMap(allocator, matrix, graph);
    // printa(graph.get(.{ .re = 7, .im = 9 }).?.values());

    var set = SetT.init(allocator);
    defer set.deinit();
    const res = try dfs(
        allocator,
        graph,
        &set,
        .{ .re = @intCast(matrix.len - 2), .im = 1 },
        // .{ .re = 15, .im = 5 },
        .{ .re = 1, .im = @intCast(matrix.len - 2) },
        // .{ .re = 15, .im = 5 },
        ComplexT.init(0, 1),
        0,
        min_distance,
    );
    // _ = res;
    printa(res);
    //     printa(graph.get(.{ .re = @intCast(matrix.len - 2), .im = 1 }).?.get(.{ .re = -1, .im = 0 }));
    //     printa(graph.get(.{ .re = 5, .im = 1 }).?.get(.{ .re = 0, .im = 1 }));
    //     printa(graph.get(.{ .re = 5, .im = 3 }).?.get(.{ .re = 1, .im = 0 }));
    //     printa(graph.get(.{ .re = 7, .im = 3 }).?.get(.{ .re = 1, .im = 0 }));
    //     printa(graph.get(.{ .re = 15, .im = 5 }).?.get(.{ .re = -1, .im = 0 }));
    //     printa(graph.get(.{ .re = 13, .im = 5 }).?.get(.{ .re = -1, .im = 0 }));
    //     printa(graph.get(.{ .re = 9, .im = 7 }).?.get(.{ .re = 0, .im = 1 }));
    //     printa(graph.get(.{ .re = 9, .im = 9 }).?.get(.{ .re = -1, .im = 0 }));
}

const PathState = struct {
    count: u32,
    pos: ComplexT,
    dir: ComplexT,
    visit: SetT,
};

fn getDirection(dir: Direction) ComplexT {
    return switch (dir) {
        .up => ComplexT.init(-1, 0),
        .down => ComplexT.init(1, 0),
        .left => ComplexT.init(0, -1),
        .right => ComplexT.init(0, 1),
    };
}

fn matrixToGraph(allocator: Allocator, matrix: []const []const u8, start_pos: ComplexT, end_pos: ComplexT) !Graph {
    var graph = Graph.init(allocator);

    var next_crossings = std.ArrayList(ComplexT).init(allocator);
    defer next_crossings.deinit();
    try next_crossings.append(start_pos);

    var direction = ComplexT.init(0, 1);

    while (next_crossings.items.len != 0) {
        const current_pos = next_crossings.pop();
        if (eql(current_pos, end_pos)) continue;
        if (graph.get(current_pos) != null) continue;

        var graph_key = GraphKey.init(allocator);
        for (0..4) |_| {
            direction = direction.mul(rot_right);
            const next_step = current_pos.add(direction);
            if (!inBounds(matrix, next_step)) continue;
            if (traversePath(allocator, matrix, next_step, direction, current_pos, end_pos)) |result| {
                try graph_key.put(direction, result);
                try next_crossings.append(result.position);
            }
        }
        try graph.put(current_pos, graph_key);
    }
    // for (0..4) |_| {
    //     direction = direction.mul(rot_right);
    //     const next_step = end_pos.add(direction);
    //     if (!inBounds(matrix, next_step)) continue;
    //     if (traversePath(allocator, matrix, next_step, end_pos)) |result| {
    //         try graph.get(end_pos).?.put(direction, result);
    //     }
    // }
    return graph;
}

fn traversePath(allocator: Allocator, matrix: []const []const u8, start: ComplexT, start_dir: ComplexT, start_crossing: ComplexT, end_pos: ComplexT) ?Tuple {
    var visited = SetT.init(allocator);
    defer visited.deinit();
    visited.put(start_crossing, {}) catch unreachable;

    var cost: u32 = 1; // We start one step from the crossing
    var steps: u32 = 1;
    var direction = start_dir;
    var position = start;
    while (true) {
        if (visited.get(position) != null) return null;
        visited.put(position, {}) catch unreachable;

        if (isCrossing(matrix, position) or eql(position, end_pos)) {
            return Tuple{ .value = cost, .position = position, .steps = steps, .direction = direction };
        }

        for (rotations) |rot| {
            const new_rotation = direction.mul(rot);
            const next_step = position.add(new_rotation);
            if (!inBounds(matrix, next_step)) continue;
            position = next_step;
            cost += 1;
            steps += 1;
            if (!eql(rot, rotations[0])) {
                cost += 1000;
                direction = new_rotation;
            }
            break;
        }
    }
}

fn isCrossing(matrix: []const []const u8, position: ComplexT) bool {
    var direction = ComplexT.init(0, 1);
    var count: u8 = 0;
    for (0..4) |_| {
        direction = direction.mul(rot_right);
        const next_step = position.add(direction);
        if (!inBounds(matrix, next_step)) continue;
        count += 1;
        if (count >= 3) return true;
    }
    return false;
}
// Graph :: Crossing -> {Direction: (next crossing, cost)}

const Tuple = struct {
    position: ComplexT,
    direction: ComplexT,
    value: u32,
    steps: u32,

    const Self = @This();

    fn lessThan(_: void, a: Self, b: Self) bool {
        return a.value < b.value;
    }
};
const GraphKey = std.ArrayHashMap(ComplexT, Tuple, HashCtx, true);
const Graph = std.ArrayHashMap(ComplexT, GraphKey, HashCtx, true);

fn dfs(
    allocator: Allocator,
    graph: Graph,
    visit: *SetT,
    curr_node: ComplexT,
    end_node: ComplexT,
    direction: ComplexT,
    cost: u32,
    target_cost: u32,
) !?u32 {
    if (cost > target_cost) return null;
    if (eql(curr_node, end_node)) {
        if (cost == target_cost) return 1;
        return null;
    }
    try visit.*.put(curr_node, {});
    defer _ = visit.*.orderedRemove(curr_node);

    var paths: u32 = 0;
    if (graph.get(curr_node)) |graph_key| {
        for (rotations) |rot| {
            const new_direction = direction.mul(rot);
            if (graph_key.get(new_direction)) |tup| {
                if (visit.*.get(tup.position) != null) continue;
                var new_cost = cost + tup.value;

                if (!eql(rot, rotations[0])) {
                    new_cost += 1000;
                }

                if (try dfs(allocator, graph, visit, tup.position, end_node, tup.direction, new_cost, target_cost)) |res| {
                    paths += res;
                }
            }
        }
    }
    return paths;
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
