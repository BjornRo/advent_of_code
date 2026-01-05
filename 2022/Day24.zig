const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const CT = i16;
const Pos = struct { row: CT, col: CT };
const Direction = enum { N, S, E, W };
const Blizzard = struct { row: CT, col: CT, direction: Direction };
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const alloc, const is_debug = if (@import("builtin").mode == .Debug)
        .{ debug_allocator.allocator(), true }
    else
        .{ std.heap.smp_allocator, false };
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
    var blizzards: std.ArrayList(Blizzard) = .empty;
    defer blizzards.deinit(alloc);

    for (1..grid.rows - 1) |i| for (1..grid.cols - 1) |j| {
        const elem = grid.get(i, j);
        if (elem == '.') continue;
        const dir: Direction = switch (elem) {
            '^' => .N,
            'v' => .S,
            '<' => .W,
            else => .E,
        };
        try blizzards.append(alloc, .{ .row = @intCast(i), .col = @intCast(j), .direction = dir });
    };

    const rows: u16 = @truncate(grid.rows - 1);
    const cols: u16 = @truncate(grid.cols - 1);
    var map = try utils.Matrix.empty(alloc, grid.rows, grid.cols);
    defer alloc.free(map.data);

    const result = try solver(alloc, &map, rows, cols, blizzards.items, false);
    return .{
        .p1 = result,
        .p2 = result +
            try solver(alloc, &map, rows, cols, blizzards.items, true) +
            try solver(alloc, &map, rows, cols, blizzards.items, false),
    };
}
inline fn getCross(comptime T: type, row: T, col: T) [5][2]T {
    return @bitCast([10]T{ row + 1, col, row, col + 1, row - 1, col, row, col - 1, row, col });
}
inline fn updateBlizzards(map: *utils.Matrix, blizzards: []Blizzard) void {
    for (blizzards) |*b| {
        switch (b.direction) {
            .N => b.row = if (b.row == 1) @intCast(map.rows - 2) else b.row - 1,
            .S => b.row = if (b.row == map.rows - 2) 1 else b.row + 1,
            .W => b.col = if (b.col == 1) @intCast(map.cols - 2) else b.col - 1,
            .E => b.col = if (b.col == map.cols - 2) 1 else b.col + 1,
        }
        map.set(@intCast(b.row), @intCast(b.col), 1);
    }
}
fn solver(alloc: Allocator, map: *utils.Matrix, rows: u16, cols: u16, blizzards: []Blizzard, swap_end: bool) !usize {
    var end: Pos = .{ .row = @intCast(rows), .col = @intCast(cols - 1) };
    var start: Pos = .{ .row = 0, .col = 1 };
    if (swap_end) std.mem.swap(Pos, &start, &end);

    const elems = (rows - 4) * (cols - 4) - blizzards.len / 2;
    var states: std.ArrayList(Pos) = try .initCapacity(alloc, elems);
    var next_states: @TypeOf(states) = try .initCapacity(alloc, elems);
    defer states.deinit(alloc);
    defer next_states.deinit(alloc);

    try states.append(alloc, start);
    for (1..1000) |i| {
        defer @memset(map.data, 0);
        updateBlizzards(map, blizzards);
        for (states.items) |state| for (getCross(CT, state.row, state.col)) |delta| {
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
    return 0;
}
