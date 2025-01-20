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

    var start_pos: Point = undefined;
    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        try matrix.append(row);
        if (std.mem.indexOfScalar(u8, row, '@')) |col|
            start_pos = Point.init(@intCast(matrix.items.len), @intCast(col));
    }

    const result = try depthBfs(
        allocator,
        matrix.items,
        start_pos,
        myf.FixedBuffer(u8, 26).init(),
        0,
    );
    print(result);

    // std.debug.print("{s}\n", .{input});
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

const State = struct { pos: Point, steps: u32 = 0 };

fn depthBfs(
    allocator: Allocator,
    matrix: []const []const u8,
    pos: Point,
    keys: myf.FixedBuffer(u8, 26),
    steps: u32,
) !u32 {
    var visited = Map.init(allocator);
    defer visited.deinit();

    var queue = try Deque(State).init(allocator);
    defer queue.deinit();
    try queue.pushBack(.{ .pos = pos, .steps = steps });

    var min_steps = ~@as(u32, 0);
    while (queue.popFront()) |*state| {
        if (try visited.fetchPut(state.pos, {}) != null or state.steps >= min_steps) continue;

        const row, const col = state.pos.array();
        for (myf.getNextPositions(row, col)) |next_pos| {
            const next_point = Point.initA(next_pos);
            const next_row, const next_col = next_point.cast();
            const tile = matrix[next_row][next_col];
            if (tile == '#') continue;
            if ('A' <= tile and tile <= 'Z' and !keys.contains(tile + 32)) continue;
            if ('a' <= tile and tile <= 'z' and !keys.contains(tile)) {
                var new_keys = keys;
                new_keys.appendAssumeCapacity(tile);
                if (new_keys.isFull()) {
                    return state.steps;
                }
                const result = try depthBfs(allocator, matrix, next_point, new_keys, state.steps + 1);
                if (result < min_steps) min_steps = result;
            } else try queue.pushBack(.{ .pos = next_point, .steps = state.steps + 1 });
        }
    }
    return min_steps;
}
