const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const CT = i16;

const GraphValue = std.BoundedArray(struct { symbol: u32, steps: u16, doors: u32 }, 26);
const Graph = std.AutoHashMap(u32, GraphValue);

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
    fn addOffset(self: Self, off: [2]CT) Self {
        return Self.init(self.row + off[0], self.col + off[1]);
    }
    fn eq(self: Self, o: Self) bool {
        return self.row == o.row and self.col == o.col;
    }
    fn cast(self: Self) [2]u16 {
        return .{ @intCast(self.row), @intCast(self.col) };
    }
    fn array(self: Self) [2]CT {
        return .{ self.row, self.col };
    }
    const HashCtx = struct {
        pub fn hash(_: @This(), key: Self) u64 {
            return @intCast(std.hash.uint32(@bitCast(key.array())));
        }
        pub fn eql(_: @This(), a: Self, b: Self) bool {
            return a.eq(b);
        }
    };
};

fn containsSymbols(keys: u32, symbol: u32, doors: u32) bool {
    return (keys & symbol) == symbol or (keys & doors) != doors;
}

fn symbolToKey(char: u8) u32 {
    const offset = switch (char) {
        'a'...'z' => char - 'a',
        'A'...'Z' => char - 'A',
        '@' => return 0,
        else => unreachable,
    };
    return std.math.powi(u32, 2, offset) catch unreachable;
}

fn genGraph(allocator: Allocator, matrix: []const []const u8, start_pos: Point) !Graph {
    var queue = try Deque(struct { pos: Point, steps: u16 = 0, doors: u32 = 0 }).init(allocator);
    var visited = std.HashMap(Point, void, Point.HashCtx, 80).init(allocator);
    defer inline for (.{ queue, &visited }) |i| i.deinit();

    var visited_symbols: u32 = 0;
    var graph = Graph.init(allocator);
    var stack = try std.BoundedArray(Point, 26).init(0);
    stack.appendAssumeCapacity(start_pos);
    while (stack.popOrNull()) |*symbol_pos| {
        const symbol: u8 = blk: {
            const row, const col = symbol_pos.cast();
            break :blk matrix[row][col];
        };
        var neighbors = try GraphValue.init(0);
        visited.clearRetainingCapacity();

        try queue.pushBack(.{ .pos = symbol_pos.* });
        while (queue.popFront()) |*const_state| {
            var state = const_state.*;
            if (try visited.fetchPut(state.pos, {}) != null) continue;

            const row, const col = state.pos.array();
            switch (matrix[@intCast(row)][@intCast(col)]) {
                'A'...'Z' => |tile| state.doors |= symbolToKey(tile),
                'a'...'z' => |tile| if (tile != symbol) {
                    const key = symbolToKey(tile);
                    neighbors.appendAssumeCapacity(.{
                        .symbol = key,
                        .steps = state.steps,
                        .doors = state.doors,
                    });
                    if ((visited_symbols & key) != key) {
                        visited_symbols |= key;
                        stack.appendAssumeCapacity(state.pos);
                    }
                },
                else => {},
            }

            for (myf.getNextPositions(row, col)) |next_pos| {
                const next_point = Point.initA(next_pos);
                const next_row, const next_col = next_point.cast();
                if (matrix[next_row][next_col] == '#') continue;
                try queue.pushBack(.{ .pos = next_point, .steps = state.steps + 1, .doors = state.doors });
            }
        }
        try graph.put(symbolToKey(symbol), neighbors);
    }
    return graph;
}

fn part1(allocator: Allocator, matrix: []const []const u8, start_pos: Point, target_keys: u32) !u16 {
    const FrontierState = struct {
        pos: u32 = symbolToKey('@'),
        steps: u16 = 0,
        keys: u32 = 0,

        const Self = @This();
        fn cmp(_: void, a: Self, b: Self) std.math.Order {
            if (a.steps < b.steps) return .lt;
            if (a.steps > b.steps) return .gt;
            return .eq;
        }
    };

    const VisitKey = struct {
        pos: u32,
        keys: u32,

        const Self = @This();
        const HashCtx = struct {
            pub fn hash(_: @This(), key: Self) u64 {
                const char_val = std.math.log2_int(u32, (key.pos << 1) + 1); // 1 to 27 [a-z@]
                const keys = key.keys << 6; // 26 chars + 6 = 32 bits
                return @intCast(std.hash.uint32(keys | char_val));
            }
            pub fn eql(_: @This(), a: Self, b: Self) bool {
                return a.pos == b.pos and a.keys == b.keys;
            }
        };
    };

    var graph = try genGraph(allocator, matrix, start_pos);
    var pqueue = PriorityQueue(FrontierState, void, FrontierState.cmp).init(allocator, undefined);
    var min_visited = std.HashMap(VisitKey, u16, VisitKey.HashCtx, 80).init(allocator);
    defer inline for (.{ pqueue, &min_visited, &graph }) |i| i.deinit();

    try pqueue.add(.{});
    var min_steps = ~@as(u16, 0);
    while (pqueue.removeOrNull()) |*state| {
        if (state.keys == target_keys) {
            if (state.steps < min_steps) min_steps = state.steps;
            continue;
        }
        if (state.steps >= min_steps) continue;

        const result = try min_visited.getOrPut(.{ .keys = state.keys, .pos = state.pos });
        if (result.found_existing) {
            if (result.value_ptr.* <= state.steps) continue;
            result.value_ptr.* = state.steps;
        } else result.value_ptr.* = state.steps;

        for (graph.get(state.pos).?.slice()) |next_pos| {
            if (containsSymbols(state.keys, next_pos.symbol, next_pos.doors)) continue;
            try pqueue.add(.{
                .pos = next_pos.symbol,
                .steps = state.steps + next_pos.steps,
                .keys = state.keys | next_pos.symbol,
            });
        }
    }
    return min_steps;
}

fn part2(allocator: Allocator, matrix: []const []const u8, start_pos: Point, target_keys: u32) !u16 {
    const VisitKeyQuad = struct {
        pos: [4]u32,
        keys: u32,

        const Self = @This();
        const HashCtx = struct {
            pub fn hash(_: @This(), key: Self) u64 {
                var bits: u64 = @intCast(key.keys);
                for (key.pos) |pos| {
                    bits <<= 8;
                    bits |= std.math.log2_int(u64, @intCast((pos << 1) + 1));
                }
                const c: [8]u8 = @bitCast(bits);
                return std.hash.CityHash64.hash(&c);
            }
            pub fn eql(_: @This(), a: Self, b: Self) bool {
                for (a.pos, b.pos) |x, y| if (x != y) return false;
                return a.keys == b.keys;
            }
        };
    };

    const FrontierStateQuad = struct {
        pos: [4]u32 = .{symbolToKey('@')} ** 4,
        steps: u16 = 0,
        keys: u32 = 0,

        const Self = @This();
        fn cmp(_: void, a: Self, b: Self) std.math.Order {
            if (a.steps < b.steps) return .lt;
            if (a.steps > b.steps) return .gt;
            return .eq;
        }
    };

    var graphs: [4]Graph = blk: {
        var new_matrix = try myf.copyMatrix(allocator, matrix);
        defer myf.freeMatrix(allocator, new_matrix);
        new_matrix[@intCast(start_pos.row)][@intCast(start_pos.col)] = '#';

        for (myf.getNextPositions(start_pos.row, start_pos.col)) |np|
            new_matrix[@intCast(np[0])][@intCast(np[1])] = '#';
        var graphs: [4]Graph = undefined;
        // upper left, upper right, lower left, lower right
        for (&graphs, [_][2]CT{ .{ -1, -1 }, .{ -1, 1 }, .{ 1, -1 }, .{ 1, 1 } }) |*g, next_pos| {
            const next_point = start_pos.addOffset(next_pos);
            new_matrix[@intCast(next_point.row)][@intCast(next_point.col)] = '@';
            g.* = try genGraph(allocator, new_matrix, next_point);
        }
        break :blk graphs;
    };
    var pqueue = PriorityQueue(FrontierStateQuad, void, FrontierStateQuad.cmp).init(allocator, undefined);
    var min_visited = std.HashMap(VisitKeyQuad, u16, VisitKeyQuad.HashCtx, 80).init(allocator);
    defer inline for (.{ pqueue, &min_visited }) |i| i.deinit();
    defer for (&graphs) |*g| g.deinit();

    try pqueue.add(.{});
    var min_steps = ~@as(u16, 0);
    while (pqueue.removeOrNull()) |*state| {
        if (state.keys == target_keys) {
            if (state.steps < min_steps) min_steps = state.steps;
            continue;
        }
        if (state.steps >= min_steps) continue;

        const result = try min_visited.getOrPut(.{ .keys = state.keys, .pos = state.pos });
        if (result.found_existing) {
            if (result.value_ptr.* <= state.steps) continue;
            result.value_ptr.* = state.steps;
        } else result.value_ptr.* = state.steps;

        for (state.pos, graphs, 0..) |pos, graph, i| for (graph.get(pos).?.slice()) |next_pos| {
            if (containsSymbols(state.keys, next_pos.symbol, next_pos.doors)) continue;
            var new_pos = state.pos;
            new_pos[i] = next_pos.symbol;
            try pqueue.add(.{
                .pos = new_pos,
                .steps = state.steps + next_pos.steps,
                .keys = state.keys | next_pos.symbol,
            });
        };
    }
    return min_steps;
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
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
    // End setup

    var matrix = std.ArrayList([]const u8).init(allocator);
    defer matrix.deinit();

    var start_pos: Point = undefined;
    var target_keys: u32 = 0;

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        for (row, 0..) |c, j| {
            if ('a' <= c and c <= 'z') target_keys |= symbolToKey(c);
            if (c == '@') start_pos = Point.init(@intCast(matrix.items.len), @intCast(j));
        }
        try matrix.append(row);
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        try part1(allocator, matrix.items, start_pos, target_keys),
        try part2(allocator, matrix.items, start_pos, target_keys),
    });
}
