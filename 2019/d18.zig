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

const Map = std.HashMap(Point, void, Point.HashCtx, 80);
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
    fn add(self: Self, o: Self) Self {
        return Self.init(self.row + o.row, self.col + o.col);
    }
    fn sub(self: Self, o: Self) Self {
        return Self.init(self.row - o.row, self.col - o.col);
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
            const c: [4]u8 = @bitCast([2]CT{ key.row, key.col });
            return std.hash.CityHash64.hash(&c);
        }
        pub fn eql(_: @This(), a: Self, b: Self) bool {
            return a.eq(b);
        }
    };
};

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

    var symbol_list = try std.BoundedArray(Point, 27).init(0);

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        for (row, 0..) |c, j| {
            if ('a' <= c and c <= 'z' or c == '@')
                symbol_list.appendAssumeCapacity(Point.init(@intCast(matrix.items.len), @intCast(j)));
        }
        try matrix.append(row);
    }

    var graph = try genGraph(allocator, matrix.items, symbol_list.slice());
    defer graph.deinit();
    for (graph.get('@').?.slice()) |r| {
        // print(r);
        std.debug.print("{c} {d} {s}\n", .{ r.symbol, r.steps, r.doors.getSlice() });
    }
    for (graph.get('s').?.slice()) |r| {
        // print(r);
        std.debug.print("{c} {d} {s}\n", .{ r.symbol, r.steps, r.doors.getSlice() });
    }
    for (graph.get('m').?.slice()) |r| {
        // print(r);
        std.debug.print("{c} {d} {s}\n", .{ r.symbol, r.steps, r.doors.getSlice() });
    }

    prints("Graph generated");
    print(try bfs(allocator, &graph, symbol_list.len));

    // std.debug.print("{s}\n", .{input});
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });
}

const FrontierState = struct {
    pos: u8,
    steps: u32 = 0,
    keys: Doors = Doors.init(),

    const Self = @This();
    fn cmp(_: void, a: Self, b: Self) std.math.Order {
        if (a.steps < b.steps) return .gt;
        if (a.steps > b.steps) return .lt;
        return .eq;
    }
};

const VisitKey = struct {
    pos: u8,
    keys: []const u8,

    const Self = @This();
    const HashCtx = struct {
        pub fn hash(_: @This(), key: Self) u64 {
            var hashr = std.hash.Fnv1a_64.init();
            hashr.update(&[1]u8{key.pos});
            hashr.update(key.keys);
            return hashr.final();
        }
        pub fn eql(_: @This(), a: Self, b: Self) bool {
            return a.pos == b.pos and std.mem.eql(u8, a.keys, b.keys);
        }
    };
};

const Visited = std.HashMap(VisitKey, u32, VisitKey.HashCtx, 80);

fn bfs(allocator: Allocator, graph: *const Graph, target_keys: u8) !u32 {
    var pqueue = PriorityQueue(FrontierState, void, FrontierState.cmp).init(allocator, undefined);
    defer pqueue.deinit();
    var stack = std.ArrayList(FrontierState).init(allocator);
    defer stack.deinit();
    var queue = try Deque(FrontierState).init(allocator);
    defer queue.deinit();

    var min_visited = Visited.init(allocator);
    defer {
        var mvi_it = min_visited.keyIterator();
        while (mvi_it.next()) |v| allocator.free(v.*.keys);
        min_visited.deinit();
    }

    try pqueue.add(.{ .pos = '@' });
    var min_steps = ~@as(u32, 0);
    while (pqueue.removeOrNull()) |*const_state| {
        var state = const_state.*;

        if (state.steps >= min_steps or state.keys.contains(state.pos)) continue;
        state.keys.appendAssumeCapacity(state.pos);
        std.mem.sort(u8, state.keys.buf[0..state.keys.len], {}, std.sort.asc(u8));
        const result = try min_visited.getOrPut(.{ .keys = state.keys.getSlice(), .pos = state.pos });
        if (result.found_existing) {
            if (result.value_ptr.* < state.steps) continue;
            result.value_ptr.* = state.steps;
        } else {
            result.key_ptr.*.keys = try allocator.dupe(u8, state.keys.getSlice());
            result.value_ptr.* = state.steps;
        }

        if (state.keys.len == target_keys) {
            print(state.steps);

            if (state.steps < min_steps) min_steps = state.steps;
            continue;
        }

        for (graph.get(state.pos).?.slice()) |next_pos| {
            if (state.keys.contains(next_pos.symbol)) continue;
            for (next_pos.doors.getSlice()) |door| {
                if (!state.keys.contains(door + 32)) break;
            } else {
                try pqueue.add(.{
                    .pos = next_pos.symbol,
                    .steps = state.steps + next_pos.steps,
                    .keys = state.keys,
                });
            }
        }
    }
    return min_steps;
}

const Doors = myf.FixedBuffer(u8, 27);
const Neighbor = struct { symbol: u8, steps: u32, doors: Doors = Doors.init() };
const GraphValue = std.BoundedArray(Neighbor, 26);
const Graph = std.AutoHashMap(u8, GraphValue);

const State = struct { pos: Point, steps: u32 = 0, doors: Doors = Doors.init() };

fn genGraph(allocator: Allocator, matrix: []const []const u8, symbol_position: []const Point) !Graph {
    var graph = Graph.init(allocator);
    var visited = Map.init(allocator);
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

        try queue.pushBack(.{ .pos = symbol_pos.*, .steps = 0 });
        while (queue.popFront()) |*const_state| {
            var state = const_state.*;
            if (try visited.fetchPut(state.pos, {}) != null) continue;

            const row, const col = state.pos.array();
            switch (matrix[@intCast(row)][@intCast(col)]) {
                'A'...'Z' => |tile| state.doors.appendAssumeCapacity(tile),
                'a'...'z' => |tile| if (tile != symbol) neighbors.appendAssumeCapacity(.{
                    .doors = state.doors,
                    .steps = state.steps,
                    .symbol = tile,
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
        try graph.put(symbol, neighbors);
    }
    return graph;
}
