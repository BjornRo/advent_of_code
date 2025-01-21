const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

fn part1(allocator: Allocator, graph: *const Graph, start: u16, target: u16) !u16 {
    const FrontierState = struct {
        pos: u16,
        steps: u16 = 0,

        const Self = @This();
        fn cmp(_: void, a: Self, b: Self) std.math.Order {
            if (a.steps < b.steps) return .lt;
            if (a.steps > b.steps) return .gt;
            return .eq;
        }
    };

    var distances = std.AutoHashMap(u16, u16).init(allocator);
    var pqueue = PriorityQueue(FrontierState, void, FrontierState.cmp).init(allocator, undefined);
    defer inline for (.{ pqueue, &distances }) |i| i.deinit();

    try pqueue.add(.{ .pos = start });
    while (pqueue.removeOrNull()) |*const_state| {
        if (const_state.pos == target) return const_state.steps - 1;

        for ([_]u16{ const_state.pos, const_state.pos ^ (1 << 15) }) |key| {
            if (graph.get(key)) |neighbors| {
                for (neighbors.slice()) |neighbor| {
                    const neighbor_symbol = neighbor.symbol & 0x7FFF;

                    const new_cost = const_state.steps + neighbor.steps;
                    if (new_cost >= distances.get(neighbor_symbol) orelse ~@as(u16, 0)) continue;
                    prints(Convert.u16_twoChar(const_state.pos));
                    prints(Convert.u16_twoChar(neighbor.symbol));
                    prints("");
                    try distances.put(neighbor_symbol, new_cost);
                    try pqueue.add(.{ .pos = neighbor_symbol, .steps = new_cost + 1 });
                }
            }
        }
    }
    return 0;
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

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| try matrix.append(row);

    var graph = try genGraph(allocator, matrix.items);
    defer graph.deinit();
    // print(graph.get(Convert.symbol("XF", .Outside)));
    // print(isOutside(Convert.symbol("ZH", .Outside)));
    // print(isOutside(Convert.symbol("ZH", .Inside)));

    // for (graph.get(Convert.symbol("ZH", .Inside)).?.slice()) |neighbors| print(neighbors);

    // print(try part1(allocator, &graph, Convert.twoChar_u16("AA"), Convert.twoChar_u16("ZZ")));
    print(try part2(allocator, &graph, Convert.symbol("AA", .Outside), Convert.symbol("ZZ", .Outside)));

    // std.debug.print("{s}\n", .{input});
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

const CT = i16;

const GraphValue = std.BoundedArray(packed struct { symbol: u16, steps: u16 }, 4);
const Graph = std.AutoHashMap(u16, GraphValue);
const Side = enum(u1) { Inside = 0, Outside = 1 };

const Convert = struct {
    fn u16_twoChar(value: u16) [2]u8 {
        return @bitCast(value);
    }
    pub fn twoChar_u16(chars: []const u8) u16 {
        return @bitCast([2]u8{ chars[0], chars[1] });
    }
    pub fn rawSymbol(offset: Point, slice: []const u8, side: Side) u16 {
        var buf: [2]u8 = undefined;
        @memcpy(&buf, slice[0..2]);
        if (offset.row == -1 or offset.col == -1) {
            std.mem.reverse(u8, &buf);
        }
        const val: u16 = @intCast(@intFromEnum(side));
        return Convert.twoChar_u16(&buf) | (val << 15);
    }
    pub fn symbol(slice: []const u8, side: Side) u16 {
        const val: u16 = @intCast(@intFromEnum(side));
        return Convert.twoChar_u16(slice) | (val << 15);
    }
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
    fn add(self: Self, o: Point) Point {
        return Self.init(self.row + o.row, self.col + o.col);
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
            const x: u32 = @bitCast(key.array());
            return myf.hash(@intCast(x));
        }
        pub fn eql(_: @This(), a: Self, b: Self) bool {
            return a.eq(b);
        }
    };
};

fn isOutside(symbol: u16) bool {
    const value: u16 = @intCast(@intFromEnum(Side.Outside));
    return (symbol >> 15) == value;
}

fn genGraph(allocator: Allocator, matrix: []const []const u8) !Graph {
    var queue = try Deque(struct { pos: Point, steps: u16 = 0 }).init(allocator);
    var stack = std.ArrayList(struct { symbol: u16, pos: Point }).init(allocator);
    var visited = std.HashMap(Point, void, Point.HashCtx, 80).init(allocator);
    defer inline for (.{ queue, &visited, &stack }) |i| i.deinit();

    for (2..matrix.len - 2) |i| for (2..matrix[0].len - 2) |j| {
        const curr = Point.init(@intCast(i), @intCast(j));
        var empty: ?Point = null;
        var hash: u8 = 0;
        var dot: u8 = 0;
        for (myf.getNeighborOffset(CT)) |offset| {
            const off_point = Point.initA(offset);
            const nr, const nc = curr.add(off_point).cast();
            switch (matrix[nr][nc]) {
                '.' => dot += 1,
                '#' => hash += 1,
                else => empty = off_point,
            }
        }
        if (empty) |offset| {
            const row, const col = curr.cast();
            if (hash == 2 and dot == 1 and matrix[row][col] == '.') {
                var buf = myf.FixedBuffer(u8, 2).init();
                var step = curr.add(offset);
                for (0..2) |_| {
                    const nr, const nc = step.cast();
                    buf.appendAssumeCapacity(matrix[nr][nc]);
                    step = step.add(offset);
                }
                const side: Side = if (i == 2 or i == matrix.len - 3 or
                    j == 2 or j == matrix[0].len - 3) .Outside else .Inside;
                try stack.append(.{
                    .pos = curr,
                    .symbol = Convert.rawSymbol(offset, buf.getSlice(), side),
                });
            }
        }
    };

    var graph = Graph.init(allocator);
    for (stack.items) |*symbol_pos| {
        var neighbors = try GraphValue.init(0);
        visited.clearRetainingCapacity();

        try queue.pushBack(.{ .pos = symbol_pos.*.pos });
        while (queue.popFront()) |*state| {
            if (try visited.fetchPut(state.pos, {}) != null) continue;

            for (myf.getNeighborOffset(CT)) |offset| {
                const offset_point = Point.initA(offset);
                const next_pos = state.pos.add(offset_point);
                const nr, const nc = next_pos.cast();
                if (matrix[nr][nc] == '#') continue;
                if (matrix[nr][nc] != '.') {
                    var buf = myf.FixedBuffer(u8, 2).init();
                    buf.appendAssumeCapacity(matrix[nr][nc]);
                    const nnr, const nnc = next_pos.add(offset_point).cast();
                    buf.appendAssumeCapacity(matrix[nnr][nnc]);
                    const side: Side = if (state.pos.row == 2 or state.pos.row == matrix.len - 3 or
                        state.pos.col == 2 or state.pos.col == matrix[0].len - 3) .Outside else .Inside;
                    const neighbor_symbol = Convert.rawSymbol(offset_point, buf.getSlice(), side);
                    if (neighbor_symbol != symbol_pos.symbol)
                        neighbors.appendAssumeCapacity(.{
                            .symbol = neighbor_symbol,
                            .steps = state.steps,
                        });
                } else try queue.pushBack(.{ .pos = next_pos, .steps = state.steps + 1 });
            }
        }
        const result = try graph.getOrPut(symbol_pos.symbol);
        if (result.found_existing) {
            for (neighbors.slice()) |neighbor| result.value_ptr.*.appendAssumeCapacity(neighbor);
        } else result.value_ptr.* = neighbors;
    }
    return graph;
}

fn part2(allocator: Allocator, graph: *const Graph, start: u16, target: u16) !u32 {
    const VisitedCtx = struct {
        pub inline fn init(symbol: u16, next_symbol: u16, depth: u16) u64 {
            const symbol_: u64 = @intCast(symbol);
            const next_symbol_: u64 = @intCast(next_symbol);
            const depth_: u64 = @intCast(depth);
            return (symbol_ << 32) | (next_symbol_ << 16) | depth_;
        }
        pub fn hash(_: @This(), key: u64) u64 {
            return myf.hash(@intCast(key));
        }
        pub fn eql(_: @This(), a: u64, b: u64) bool {
            return a == b;
        }
    };
    const Visited = std.HashMap(u64, u32, VisitedCtx, 90);
    const FrontierState = struct {
        symbol: u16,
        steps: u32 = 0,
        depth: u16 = 0,

        const Self = @This();
        fn cmp(_: void, a: Self, b: Self) std.math.Order {
            if (a.depth > b.depth) return .gt;
            if (a.depth < b.depth) return .lt;
            if (a.steps < b.steps) return .lt;
            if (a.steps > b.steps) return .gt;
            return .eq;
        }
    };
    var distances = Visited.init(allocator);
    var pqueue = PriorityQueue(FrontierState, void, FrontierState.cmp).init(allocator, undefined);
    defer inline for (.{ pqueue, &distances }) |i| i.deinit();

    try pqueue.add(.{ .symbol = start });
    while (pqueue.removeOrNull()) |*const_state| {
        const came_from_outside = isOutside(const_state.symbol);
        if (const_state.depth == 0 and const_state.symbol == target) {
            prints("here");
            std.debug.print("{s}->{s} {d} {any}\n", .{
                Convert.u16_twoChar(const_state.symbol & 0x7fff), "X",
                // Convert.u16_twoChar(neighbor.symbol & 0x7fff),
                const_state.depth,                                came_from_outside,
            });
            return const_state.steps - 1;
        }

        if (graph.get(const_state.symbol)) |neighbors| {
            for (neighbors.slice()) |neighbor| {
                const going_to_outside = isOutside(neighbor.symbol);
                const new_cost = const_state.steps + neighbor.steps + 1;
                if (!came_from_outside and !going_to_outside) continue;

                if (const_state.depth == 0 and came_from_outside and going_to_outside) continue;

                // if ((const_state.symbol & 0x7fff) == Convert.twoChar_u16("IC")) {
                //     std.debug.print("{s} -> {s}\n", .{ Convert.u16_twoChar(const_state.symbol & 0x7fff), Convert.u16_twoChar(neighbor.symbol & 0x7fff) });
                //     // std.debug.print("out: {any}, out: {any}\n", .{ isOutside(const_state.symbol), isOutside(next_symbol) });
                //     print(const_state.depth + 1);
                //     prints("");
                // }

                const map_key = VisitedCtx.init(const_state.symbol, neighbor.symbol, const_state.depth);
                if (new_cost >= distances.get(map_key) orelse ~@as(u32, 0)) continue;
                try distances.put(map_key, new_cost);

                if (const_state.depth >= 12) return 0;

                for ([2]u16{ neighbor.symbol, neighbor.symbol ^ (1 << 15) }) |next_symbol| {
                    if (!came_from_outside and !isOutside(next_symbol)) continue;

                    var new_depth = const_state.depth;
                    if (came_from_outside and !going_to_outside) {
                        new_depth += 1;
                    } else {
                        if (new_depth == 0) continue;
                        new_depth -= 1;
                    }
                    if (new_depth == 0 and came_from_outside and isOutside(next_symbol)) continue;

                    if (new_depth == 7 and Convert.twoChar_u16("ZH") == const_state.symbol & 0x7fff) {
                        std.debug.print("b: {s} -> {s}\n", .{ Convert.u16_twoChar(const_state.symbol & 0x7fff), Convert.u16_twoChar(neighbor.symbol & 0x7fff) });
                        std.debug.print("out: {any}, out: {any}\n", .{ isOutside(const_state.symbol), isOutside(next_symbol) });
                        std.debug.print("depth: {d}, steps: {d}\n", .{ new_depth, new_cost });
                        prints("");
                        //
                    }
                    try pqueue.add(.{
                        .symbol = next_symbol,
                        .steps = new_cost,
                        .depth = new_depth,
                    });
                }
                // try pqueue.add(.{
                //     .symbol = next_symbol,
                //     .steps = new_cost,
                //     .depth = if (isOutside(const_state.symbol)) const_state.depth + 1 else const_state.depth -| 1,
                // });
            }

            // prints(Convert.u16_twoChar(const_state.symbol & 0x7fff));
            // prints(Convert.u16_twoChar(neighbor.symbol & 0x7fff));
            // prints("");

        }
    }
    return 0;
}
