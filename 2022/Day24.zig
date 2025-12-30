const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const CT = i16;
const Pos = struct { row: CT, col: CT };
const Direction = enum { N, S, E, W };
const Blizzard = struct { row: CT, col: CT, direction: Direction };
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

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
        if (elem != '.') {
            const dir: Direction = switch (elem) {
                '^' => .N,
                'v' => .S,
                '<' => .W,
                else => .E,
            };
            try blizzards.append(alloc, .{ .row = @intCast(i), .col = @intCast(j), .direction = dir });
        }
    };
    const result = try solver(alloc, grid, blizzards.items, false);
    return .{
        .p1 = result,
        .p2 = result + 2 +
            try solver(alloc, grid, blizzards.items, true) +
            try solver(alloc, grid, blizzards.items, false),
    };
}
pub fn getCross(comptime T: type, row: T, col: T) [5][2]T {
    return @bitCast([10]T{ row + 1, col, row, col + 1, row - 1, col, row, col - 1, row, col });
}
fn updateBlizzards(blizzards: []Blizzard, row: CT, col: CT) void {
    for (blizzards) |*b| {
        switch (b.direction) {
            .N => {
                b.row -= 1;
                if (b.row == 0) b.row = row - 2;
            },
            .S => {
                b.row += 1;
                if (b.row == row - 1) b.row = 1;
            },
            .W => {
                b.col -= 1;
                if (b.col == 0) b.col = col - 2;
            },
            .E => {
                b.col += 1;
                if (b.col == col - 1) b.col = 1;
            },
        }
    }
}
fn solver(alloc: Allocator, grid: utils.Matrix, blizzards: []Blizzard, swap_end: bool) !usize {
    var end: Pos = .{ .row = @intCast(grid.rows - 1), .col = @intCast(grid.cols - 2) };
    var start: Pos = .{ .row = 0, .col = 1 };
    if (swap_end) std.mem.swap(Pos, &start, &end);

    var states: std.ArrayList(Pos) = .empty;
    var next_states: @TypeOf(states) = .empty;
    defer states.deinit(alloc);
    defer next_states.deinit(alloc);

    var visited: std.AutoHashMap(Pos, void) = .init(alloc);
    defer visited.deinit();

    try states.append(alloc, start);
    for (0..1000) |i| {
        defer {
            std.mem.swap(@TypeOf(states), &states, &next_states);
            next_states.clearRetainingCapacity();
            visited.clearRetainingCapacity();
        }
        updateBlizzards(blizzards, @intCast(grid.rows), @intCast(grid.cols));
        for (states.items) |state| {
            if (std.meta.eql(state, end)) return i;
            if ((try visited.getOrPut(state)).found_existing) continue;
            for (getCross(CT, state.row, state.col)) |delta| {
                const row = delta[0];
                const col = delta[1];
                if (grid.inBounds(row, col)) {
                    if (grid.get(@intCast(row), @intCast(col)) == '#') continue;
                    for (blizzards) |b| {
                        if (b.row == row and b.col == col) break;
                    } else try next_states.append(alloc, .{ .row = row, .col = col });
                }
            }
        }
    }
    return 0;
}
