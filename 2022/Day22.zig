const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const CT = i32;
const Complex = std.math.complex.Complex(CT);
const Instruction = union(enum) { value: u8, rotation: enum { Right, Left } };
const leftRotation = Complex.init(0, 1);
const rightRotation = Complex.init(0, -1);

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d22t.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []u8) !struct { p1: CT, p2: CT } {
    const split_index = std.mem.indexOf(u8, data, "\n\n").?;
    const raw_instructions = data[split_index + 2 ..];

    const instructions = blk: {
        var instructions: std.ArrayList(Instruction) = .empty;
        defer instructions.deinit(alloc);
        var index: usize = 0;
        while (utils.firstNumber(u8, index, raw_instructions)) |item| {
            index = item.end_index;
            try instructions.append(alloc, .{ .value = item.value });
            if (index >= raw_instructions.len) break;
            try instructions.append(alloc, .{ .rotation = if (raw_instructions[index] == 'L') .Left else .Right });
        }
        break :blk try instructions.toOwnedSlice(alloc);
    };
    defer alloc.free(instructions);

    const map = blk: {
        var cols: usize = 0;
        var rows: usize = 1;
        {
            var col_start: usize = 0;
            for (data[0..split_index], 0..) |c, i|
                if (c == '\n') {
                    rows += 1;
                    cols = @max(cols, i - col_start);
                    col_start = i + 1;
                };
        }
        var map = try utils.Matrix.empty(alloc, rows + 2, cols + 2);
        @memset(map.data, ' ');
        var row_iter = std.mem.splitScalar(u8, data[0..split_index], '\n');
        rows = 1;
        while (row_iter.next()) |row| : (rows += 1) for (row, 0..) |c, i| map.set(rows, i + 1, c);
        break :blk map;
    };
    defer alloc.free(map.data);
    return .{ .p1 = try part1(map, instructions), .p2 = try part2(alloc, map, instructions) };
}

fn part2(alloc: Allocator, map: utils.Matrix, instructions: []Instruction) !CT {
    {
        // _ = alloc;
        // const cube: [6]usize = undefined;
        var dim = map.rows;
        for (1..map.rows - 1) |i| {
            const row_start = i * map.stride;
            const row = map.data[row_start + 1 .. row_start + map.stride - 1];
            const delta = std.mem.lastIndexOfAny(u8, row, ".#").? - std.mem.indexOfAny(u8, row, ".#").? + 1;
            if (delta > dim) break;
            dim = delta;
        }
        const Face = struct {
            grid: utils.Matrix,
            top_left_row: usize,
            top_left_col: usize,
        };
        var cube: [6]Face = undefined;
        var id: usize = 0;
        for (0..(map.rows - 2) / dim) |i| {
            for (0..(map.cols - 2) / dim) |j| {
                const row = i * dim + 1;
                const col = j * dim + 1;
                if (map.get(row, col) != ' ') {
                    var block = try utils.Matrix.empty(alloc, dim + 2, dim + 2);
                    @memset(block.data, ' ');
                    for (0..dim) |dr| for (0..dim) |dc| block.set(dr + 1, dc + 1, map.get(row + dr, col + dc));
                    cube[id] = .{ .grid = block, .top_left_row = i, .top_left_col = j };
                    block.print(' ');
                    id += 1;
                }
            }
        }
        defer for (cube) |c| alloc.free(c.grid.data);
        std.debug.print("{any}\n", .{cube[0]});
        std.debug.print("{any}\n", .{cube[1]});
        std.debug.print("{any}\n", .{cube[2]});
        std.debug.print("{any}\n", .{cube[3]});
    }
    var position: Complex = for (0..map.cols) |i| (if (map.get(1, i) == '.') break .init(1, @intCast(i))) else unreachable;

    var direction = Complex.init(0, 1); // Right
    for (instructions) |ins| {
        switch (ins) {
            .rotation => |r| direction = direction.mul(switch (r) {
                .Left => leftRotation,
                .Right => rightRotation,
            }),
            .value => |v| for (0..v) |_| {
                const next_position = position.add(direction);
                switch (map.get(@intCast(next_position.re), @intCast(next_position.im))) {
                    '.' => position = next_position,
                    '#' => break,
                    else => {
                        var frontier = position;
                        while (true) {
                            frontier = frontier.sub(direction);
                            const elem = map.get(@intCast(frontier.re), @intCast(frontier.im));
                            if (elem == ' ') break;
                        }
                        frontier = frontier.add(direction);
                        if (map.get(@intCast(frontier.re), @intCast(frontier.im)) == '#') break;
                        position = frontier;
                    },
                }
            },
        }
    }
    // std.debug.print("{any}\n", .{position});
    // std.debug.print("{any}\n", .{direction});
    const score: CT = if (direction.re == 0) @as(CT, if (direction.im == 1) 0 else 2) else if (direction.im == 1) 1 else 3;
    return 1000 * position.re + 4 * position.im + score;
}
fn part1(map: utils.Matrix, instructions: []Instruction) !CT {
    var position: Complex = for (0..map.cols) |i| (if (map.get(1, i) == '.') break .init(1, @intCast(i))) else unreachable;
    var direction = Complex.init(0, 1);
    for (instructions) |ins| {
        switch (ins) {
            .rotation => |r| direction = direction.mul(switch (r) {
                .Left => leftRotation,
                .Right => rightRotation,
            }),
            .value => |v| for (0..v) |_| {
                const next_position = position.add(direction);
                switch (map.get(@intCast(next_position.re), @intCast(next_position.im))) {
                    '.' => position = next_position,
                    '#' => break,
                    else => {
                        var frontier = position;
                        while (map.get(@intCast(frontier.re), @intCast(frontier.im)) != ' ')
                            frontier = frontier.sub(direction);
                        frontier = frontier.add(direction);
                        if (map.get(@intCast(frontier.re), @intCast(frontier.im)) == '#') break;
                        position = frontier;
                    },
                }
            },
        }
    }
    const score: CT = if (direction.re == 0) @as(CT, if (direction.im == 1) 0 else 2) else if (direction.im == 1) 1 else 3;
    return 1000 * position.re + 4 * position.im + score;
}
