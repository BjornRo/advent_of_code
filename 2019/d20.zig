const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    // const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    // std.debug.print("{s}\n", .{input});
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

const CT = i16;

const GraphValue = std.BoundedArray(packed struct { symbol: u16, steps: u16 }, 1200);
const Graph = std.AutoHashMap(u16, GraphValue);
const Side = enum(u1) { Inside, Outside };

const Convert = struct {
    fn twoChar_u16(chars: []const u8) u16 {
        return @bitCast([2]u8{ chars[0], chars[1] });
    }
    fn u16_twoChar(value: u16) [2]u8 {
        return @bitCast(value);
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

const VisitHashCtx = struct {
    pub inline fn init(position: u32, index: usize, keys: u32) u64 {
        const pos: u64 = std.math.log2_int(u64, @intCast((position << 1) + 1));
        const idx: u64 = @truncate(index);
        const bits: u64 = @intCast(keys);
        return bits | (pos << 32) | (idx << 48);
    }
    pub fn hash(_: @This(), key: u64) u64 {
        return myf.hash(key);
    }
    pub fn eql(_: @This(), a: u64, b: u64) bool {
        return a == b;
    }
};

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
            if (hash != 2 or dot != 1) continue;
            var buf = myf.FixedBuffer(u8, 2).init();
            var step = curr.add(offset);
            for (0..2) |_| {
                const row, const col = step.cast();
                buf.appendAssumeCapacity(matrix[row][col]);
                step = step.add(offset);
            }
            const side: Side = if (i == 2 or j == 2) .Outside else .Inside;
            try stack.append(.{
                .pos = curr,
                .symbol = Convert.rawSymbol(offset, buf.getSlice(), side),
            });
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
                    const side: Side =
                        if (state.pos.row == 2 or state.pos.col == 2) .Outside else .Inside;
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

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d20.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var matrix = std.ArrayList([]const u8).init(allocator);
    defer matrix.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| try matrix.append(row);

    var graph = try genGraph(allocator, matrix.items);
    defer graph.deinit();
    // print(graph.get(Convert.twoChar_u16("AA")));

    print(try part1(allocator, &graph, Convert.symbol("AA", .Outside), Convert.symbol("ZZ", .Outside)));
}

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

    const mask = 0x7FFF;
    var distances = std.AutoHashMap(u16, u16).init(allocator);
    var pqueue = PriorityQueue(FrontierState, void, FrontierState.cmp).init(allocator, undefined);
    defer inline for (.{ pqueue, &distances }) |i| i.deinit();

    try pqueue.add(.{ .pos = start });
    while (pqueue.removeOrNull()) |*const_state| {
        if (const_state.pos & mask == target & mask) return const_state.steps - 1;

        inline for (.{ graph.get(const_state.pos), graph.get(const_state.pos ^ (1 << 15)) }) |neighbors| {
            if (neighbors) |neighbors_| {
                for (neighbors_.slice()) |neighbor| {
                    const new_cost = const_state.steps + neighbor.steps;
                    if (new_cost >= distances.get(neighbor.symbol & mask) orelse ~@as(u16, 0)) continue;
                    prints(Convert.u16_twoChar(const_state.pos));
                    prints(Convert.u16_twoChar(neighbor.symbol));
                    prints("");
                    try distances.put(neighbor.symbol & mask, new_cost);
                    try pqueue.add(.{ .pos = neighbor.symbol, .steps = new_cost + 1 });
                }
            }
        }
    }
    return 0;
}

fn part2(allocator: Allocator, graph: *const Graph, start: u16, target: u16) !u16 {
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
        if (const_state.pos == target) {
            return const_state.steps - 1;
        }
        if (graph.get(const_state.pos)) |neighbors| {
            for (neighbors.slice()) |neighbor| {
                const new_cost = const_state.steps + neighbor.steps;
                if (new_cost < distances.get(neighbor.symbol) orelse ~@as(u16, 0)) {
                    prints(Convert.u16_twoChar(const_state.pos));
                    prints(Convert.u16_twoChar(neighbor.symbol));
                    prints("");
                    try distances.put(neighbor.symbol, new_cost);
                    try pqueue.add(.{ .pos = neighbor.symbol, .steps = new_cost + 1 });
                }
            }
        }
    }
    return 0;
}
