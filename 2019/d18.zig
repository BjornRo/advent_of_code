const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const CT = i16;

const Visited = std.HashMap(VisitKey, u16, VisitKey.HashCtx, 80);
const GraphValue = std.BoundedArray(struct { symbol: u32, steps: u16, doors: u32 }, 26);
const Graph = std.AutoHashMap(u32, GraphValue);
const PointMap = std.HashMap(Point, void, Point.HashCtx, 80);

const FrontierState = struct {
    pos: u32,
    steps: u16 = 0,
    keys: u32 = 0,

    const Self = @This();
    fn cmp(_: void, a: Self, b: Self) std.math.Order {
        if (a.steps < b.steps) return .lt;
        if (a.steps > b.steps) return .gt;
        return .eq;
    }
    fn contains(self: Self, target: u32) bool {
        return (self.keys & target) == target;
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

fn symbolToKey(char: u8) u32 {
    const offset = switch (char) {
        'a'...'z' => char - 'a',
        'A'...'Z' => char - 'A',
        '@' => return 0,
        else => unreachable,
    };
    return std.math.powi(u32, 2, offset) catch unreachable;
}

fn part1(allocator: Allocator, matrix: []const []const u8, symbol_pos: []const Point, target_keys: u32) !u16 {
    var graph = try genGraph(allocator, matrix, symbol_pos);
    defer graph.deinit();
    return try bfs(allocator, &graph, target_keys);
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

    var symbol_pos = try std.BoundedArray(Point, 27).init(0);
    var target_keys: u32 = 0;

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        for (row, 0..) |c, j| {
            if ('a' <= c and c <= 'z' or c == '@') {
                symbol_pos.appendAssumeCapacity(Point.init(@intCast(matrix.items.len), @intCast(j)));
                target_keys |= symbolToKey(c);
            }
        }
        try matrix.append(row);
    }

    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
    //     try part1(allocator, matrix.items, symbol_pos.slice(), target_keys),
    //     2,
    // });
}

fn bfs(allocator: Allocator, graph: *const Graph, target_keys: u32) !u16 {
    var pqueue = PriorityQueue(FrontierState, void, FrontierState.cmp).init(allocator, undefined);
    var min_visited = Visited.init(allocator);
    defer inline for (.{ pqueue, &min_visited }) |i| i.deinit();

    try pqueue.add(.{ .pos = symbolToKey('@') });
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
            if (state.contains(next_pos.symbol) or !state.contains(next_pos.doors)) continue;
            try pqueue.add(.{
                .pos = next_pos.symbol,
                .steps = state.steps + next_pos.steps,
                .keys = state.keys | next_pos.symbol,
            });
        }
    }
    return min_steps;
}

fn genGraph(allocator: Allocator, matrix: []const []const u8, symbol_position: []const Point) !Graph {
    const State = struct { pos: Point, steps: u16 = 0, doors: u32 = 0 };

    var graph = Graph.init(allocator);
    var visited = PointMap.init(allocator);
    defer visited.deinit();
    var queue = try Deque(State).init(allocator);
    defer queue.deinit();

    for (symbol_position) |*symbol_pos| {
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
                'a'...'z' => |tile| if (tile != symbol) neighbors.appendAssumeCapacity(.{
                    .symbol = symbolToKey(tile),
                    .steps = state.steps,
                    .doors = state.doors,
                }),
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
