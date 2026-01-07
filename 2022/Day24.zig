const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const Pos = struct { row: i16, col: i16 };
const Blizzard = struct { pos: Pos, direction: enum { N, S, E, W } };
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const alloc, const is_debug = switch (@import("builtin").mode) {
        .Debug => .{ debug_allocator.allocator(), true },
        else => .{ std.heap.smp_allocator, false },
    };
    const start = std.time.microTimestamp();
    defer {
        std.debug.print("Time: {any}s\n", .{@as(f64, @floatFromInt(std.time.microTimestamp() - start)) / 1000_000});
        if (is_debug) _ = debug_allocator.deinit();
    }
    const data = try utils.read(alloc, "in/d24.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}
fn solve(alloc: Allocator, data: []u8) !struct { p1: usize, p2: usize } {
    var grid = utils.arrayToMatrix(data);
    var blizzards: std.ArrayList(Blizzard) = try .initCapacity(alloc, grid.rows * grid.cols);
    defer blizzards.deinit(alloc);
    for (1..grid.rows - 1) |i| for (1..grid.cols - 1) |j| {
        const elem = grid.get(i, j);
        if (elem == '.') continue;
        blizzards.appendAssumeCapacity(.{ .pos = .{ .row = @intCast(i), .col = @intCast(j) }, .direction = switch (elem) {
            '^' => .N,
            'v' => .S,
            '<' => .W,
            else => .E,
        } });
    };
    var res: @Vector(3, u16) = undefined;
    for ([3]bool{ false, true, false }, 0..) |b, i|
        res[i] = try solver(alloc, &grid, @truncate(grid.rows - 1), @truncate(grid.cols - 1), blizzards.items, b);
    return .{ .p1 = res[0], .p2 = @reduce(.Add, res) };
}
inline fn getCross(comptime T: type, row: T, col: T) [5][2]T {
    return @bitCast([10]T{ row + 1, col, row, col + 1, row - 1, col, row, col - 1, row, col });
}
inline fn updateBlizzards(map: *utils.Matrix, blizzards: []Blizzard) void {
    for (blizzards) |*b| {
        switch (b.direction) {
            .N => b.pos.row = if (b.pos.row == 1) @intCast(map.rows - 2) else b.pos.row - 1,
            .S => b.pos.row = if (b.pos.row == map.rows - 2) 1 else b.pos.row + 1,
            .W => b.pos.col = if (b.pos.col == 1) @intCast(map.cols - 2) else b.pos.col - 1,
            .E => b.pos.col = if (b.pos.col == map.cols - 2) 1 else b.pos.col + 1,
        }
        map.set(@intCast(b.pos.row), @intCast(b.pos.col), 1);
    }
}
fn solver(alloc: Allocator, map: *utils.Matrix, rows: u16, cols: u16, blizzards: []Blizzard, swap_end: bool) !u16 {
    var end: Pos = .{ .row = @intCast(rows), .col = @intCast(cols - 1) };
    var start: Pos = .{ .row = 0, .col = 1 };
    if (swap_end) std.mem.swap(Pos, &start, &end);

    const elems = (rows - 4) * (cols - 4) - blizzards.len / 2;
    var states: std.ArrayList(Pos) = try .initCapacity(alloc, elems);
    var next_states: @TypeOf(states) = try .initCapacity(alloc, elems);
    defer states.deinit(alloc);
    defer next_states.deinit(alloc);

    try states.append(alloc, start);
    var i: u16 = 1;
    while (true) : (i += 1) {
        @memset(map.data, 0);
        updateBlizzards(map, blizzards);
        for (states.items) |state| for (getCross(@TypeOf(end.row), state.row, state.col)) |delta| {
            if (delta[0] == end.row and delta[1] == end.col) return i;
            if (delta[0] <= 0 or delta[0] >= rows or delta[1] <= 0 or delta[1] >= cols) continue;
            const tile = map.get(@intCast(delta[0]), @intCast(delta[1]));
            if (tile >= 1) continue;
            map.set(@intCast(delta[0]), @intCast(delta[1]), tile | 2);
            next_states.appendAssumeCapacity(.{ .row = delta[0], .col = delta[1] });
        };
        std.mem.swap(@TypeOf(states), &states, &next_states);
        next_states.clearRetainingCapacity();
    }
}
