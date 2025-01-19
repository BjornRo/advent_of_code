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

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| try matrix.append(row);

    const result = try part1(allocator, matrix.items);
    print(result);

    // std.debug.print("{s}\n", .{input});
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

const State = struct {
    pos: Point,
    visited: Map,
    steps: u16 = 0,
    keys: myf.FixedBuffer(u8, 26) = myf.FixedBuffer(u8, 26).init(),
};

fn part1(allocator: Allocator, matrix: []const []const u8) !u32 {
    const start_pos: Point = outer: for (0..matrix.len) |i| {
        for (0..matrix[0].len) |j|
            if (matrix[i][j] == '@') break :outer Point.init(@intCast(i), @intCast(j));
    } else unreachable;

    var stack = std.ArrayList(State).init(allocator);
    defer stack.deinit();

    try stack.append(State{ .pos = start_pos, .visited = Map.init(allocator) });

    var min_steps = ~@as(u32, 0);
    while (stack.popOrNull()) |*const_state| {
        var state = const_state.*;
        defer state.visited.deinit();
        if (state.keys.isFull()) {
            if (state.steps < min_steps) min_steps = state.steps;
            continue;
        }

        if (try state.visited.fetchPut(state.pos, {}) != null or state.steps >= min_steps) continue;

        const row, const col = state.pos.array();
        for (myf.getNextPositions(row, col)) |next_pos| {
            const next_point = Point.initA(next_pos);
            const next_row, const next_col = next_point.cast();
            const tile = matrix[next_row][next_col];
            if (tile == '#') continue;
            if ('A' <= tile and tile <= 'Z' and !state.keys.contains(tile + 32)) continue;
            const item = try stack.addOne(); // to avoid copying too much.
            item.* = .{
                .keys = state.keys,
                .pos = next_point,
                .steps = state.steps + 1,
                .visited = try state.visited.clone(),
            };
            if ('a' <= tile and tile <= 'z' and !state.keys.contains(tile)) {
                try item.keys.append(tile);
                item.visited.clearRetainingCapacity();
            }
        }
    }
    return min_steps;
}
