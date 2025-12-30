const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const CT = i32;
const Complex = std.math.complex.Complex(CT);
const Vec3 = @Vector(3, CT);
const Instruction = union(enum) { value: u8, rotation: enum { Right, Left } };
const Direction = enum { Up, Down, Left, Right };
const Orientation = struct {
    Normal: Vec3,
    Up: Vec3,
    Right: Vec3,
    fn unpack(self: @This()) [3]Vec3 {
        return .{ self.Normal, self.Up, self.Right };
    }
};
const Face = struct { grid: utils.Matrix, top_left_row: usize, top_left_col: usize };
const FaceNeighbors = struct { up: usize, down: usize, left: usize, right: usize };
const neg: Vec3 = @splat(-1);
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
fn cubeConvert(alloc: Allocator, map: utils.Matrix) !struct { [6]utils.Matrix, [6]FaceNeighbors, [6]Orientation } {
    var dim = map.rows;
    for (1..map.rows - 1) |i| {
        const row_start = i * map.stride;
        const row = map.data[row_start + 1 .. row_start + map.stride - 1];
        const delta = std.mem.lastIndexOfAny(u8, row, ".#").? - std.mem.indexOfAny(u8, row, ".#").? + 1;
        if (delta > dim) break;
        dim = delta;
    }
    var cube: [6]Face = undefined;
    var id: usize = 0;
    for (0..(map.rows - 2) / dim) |i| for (0..(map.cols - 2) / dim) |j| {
        const row = i * dim + 1;
        const col = j * dim + 1;
        if (map.get(row, col) == ' ') continue;
        var block = try utils.Matrix.empty(alloc, dim + 2, dim + 2);
        @memset(block.data, ' ');
        for (0..dim) |dr| for (0..dim) |dc| block.set(dr + 1, dc + 1, map.get(row + dr, col + dc));
        cube[id] = .{ .grid = block, .top_left_row = i, .top_left_col = j };
        id += 1;
    };
    var neighbors: [6]FaceNeighbors = undefined;
    for (cube, 0..) |c, i| {
        const row: i8 = @intCast(c.top_left_row);
        const col: i8 = @intCast(c.top_left_col);
        var adjacent: FaceNeighbors = .{ .up = 99, .down = 99, .left = 99, .right = 99 };
        for (cube, 0..) |a, j| {
            if (i == j) continue;
            const arow: i8 = @intCast(a.top_left_row);
            const acol: i8 = @intCast(a.top_left_col);
            if (arow == row - 1 and acol == col)
                adjacent.up = j
            else if (arow == row + 1 and acol == col)
                adjacent.down = j
            else if (arow == row and acol == col - 1)
                adjacent.left = j
            else if (arow == row and acol == col + 1)
                adjacent.right = j;
        }
        neighbors[i] = adjacent;
    }
    var queue: Deque(usize) = try .init(alloc);
    defer queue.deinit();

    var orientations: [6]?Orientation = @splat(null);
    orientations[0] = .{ .Normal = .{ 0, 0, 1 }, .Up = .{ 0, -1, 0 }, .Right = .{ 1, 0, 0 } };

    try queue.pushBack(0);
    while (queue.popFront()) |i| {
        const n = neighbors[i];
        for ([4]usize{ n.up, n.down, n.left, n.right }, [4]Direction{ .Up, .Down, .Left, .Right }) |f, d|
            if (f != 99) if (orientations[f] == null) {
                orientations[f] = rotate(orientations[i].?, d);
                try queue.pushBack(f);
            };
    }
    for (0..6) |i| {
        _, const u, const r = orientations[i].?.unpack();
        var c = &neighbors[i];
        // check neg here
        for ([4]*usize{ &c.up, &c.down, &c.left, &c.right }, [4]Vec3{ u, u * neg, r, r * neg }) |f, vec|
            for (0..6) |j| {
                if (i == j) continue;
                const n, _, _ = orientations[j].?.unpack();
                if (std.simd.countTrues(vec == n) == 3) f.* = j;
            };
    }
    var new_orientations: [6]Orientation = undefined;
    var new_face: [6]utils.Matrix = undefined;
    for (0..6) |i| {
        new_face[i] = cube[i].grid;
        new_orientations[i] = orientations[i].?;
        // std.debug.print("{d}: {any}\n", .{ i + 1, orientations[i] });
        // std.debug.print("{d}: {any}\n", .{ i + 1, neighbors[i] });
    }
    return .{ new_face, neighbors, new_orientations };
}
fn rotate(ori: Orientation, dir: Direction) Orientation {
    const n, const u, const r = ori.unpack();
    return switch (dir) {
        .Up => .{ .Normal = u, .Up = n * neg, .Right = r },
        .Down => .{ .Normal = u * neg, .Up = n, .Right = r },
        .Left => .{ .Normal = r, .Up = u, .Right = n * neg },
        .Right => .{ .Normal = r * neg, .Up = u, .Right = n },
    };
}
fn getDir(c: Complex) Direction {
    if (c.re == 0) (if (c.im == -1) return .Left else return .Right);
    return if (c.re == -1) .Up else .Down;
}
fn dirToCompex(dir: Direction) Complex {
    return switch (dir) {
        .Up => .init(-1, 0),
        .Down => .init(1, 0),
        .Left => .init(0, -1),
        .Right => .init(0, 1),
    };
}
fn dot(a: Vec3, b: Vec3) CT {
    const ax, const ay, const az = a;
    const bx, const by, const bz = b;
    return ax * bx + ay * by + az * bz;
}
fn part2(alloc: Allocator, map: utils.Matrix, instructions: []Instruction) !CT {
    const face, const neighbors, const orientation = try cubeConvert(alloc, map);
    defer for (face) |f| alloc.free(f.data);

    var id: usize = 0;
    var position: Complex = for (0..face[id].cols) |i| (if (face[id].get(1, i) == '.') break .init(1, @intCast(i))) else unreachable;

    var direction = Complex.init(0, 1); // Right
    for (instructions[0..3]) |ins| {
        switch (ins) {
            .rotation => |r| direction = direction.mul(switch (r) {
                .Left => leftRotation,
                .Right => rightRotation,
            }),
            .value => |v| for (0..v) |_| {
                const next_position = position.add(direction);
                std.debug.print("{any}\n", .{next_position});
                switch (face[id].get(@intCast(next_position.re), @intCast(next_position.im))) {
                    '.' => position = next_position,
                    '#' => break,
                    else => {
                        std.debug.print("new face\n", .{});
                        const dir = getDir(direction);
                        const next_id = switch (dir) {
                            .Up => neighbors[id].up,
                            .Down => neighbors[id].down,
                            .Left => neighbors[id].left,
                            .Right => neighbors[id].right,
                        };
                        const new_dir: Complex = blk: {
                            const vec = switch (dir) {
                                .Up => orientation[id].Up,
                                .Down => orientation[id].Up * neg,
                                .Left => orientation[id].Right * neg,
                                .Right => orientation[id].Right,
                            };
                            const dot_up = dot(vec, orientation[next_id].Up);
                            const dot_right = dot(vec, orientation[next_id].Right);
                            break :blk if (dot_up == 1)
                                dirToCompex(.Up)
                            else if (dot_up == -1)
                                dirToCompex(.Down)
                            else if (dot_right == -1)
                                dirToCompex(.Left)
                            else
                                dirToCompex(.Right);
                        };
                        var frontier: Complex = blk: {
                            const dim: CT = @intCast(face[0].rows);
                            var row = position.re;
                            var col = position.im;
                            switch (dir) {
                                .Up, .Down => {
                                    if (dot(orientation[id].Right, orientation[next_id].Right) == -1) {
                                        col = dim - 1 - col;
                                        row = 1;
                                    }
                                },
                                .Left, .Right => {
                                    if (dot(orientation[id].Up, orientation[next_id].Up) == -1) {
                                        row = dim - 1 - row;
                                        col = 1;
                                    }
                                },
                            }
                            break :blk .{ .re = row, .im = col };
                        };
                        std.debug.print("{any}f\n", .{frontier});
                        // 0: .{ .Normal = { 0, 0, 1 }, .Up = { 0, -1, 0 }, .Right = { 1, 0, 0 } }
                        // 0: .{ .up = 1, .down = 3, .left = 2, .right = 5 }
                        // 1: .{ .Normal = { 0, -1, 0 }, .Up = { 0, 0, 1 }, .Right = { -1, 0, 0 } }
                        // 1: .{ .up = 0, .down = 4, .left = 5, .right = 2 }
                        // 2: .{ .Normal = { 1, 0, 0 }, .Up = { 0, 0, 1 }, .Right = { 0, -1, 0 } }
                        // 2: .{ .up = 0, .down = 4, .left = 1, .right = 3 }
                        // 3: .{ .Normal = { 0, 1, 0 }, .Up = { 0, 0, 1 }, .Right = { 1, 0, 0 } }
                        // 3: .{ .up = 0, .down = 4, .left = 2, .right = 5 }
                        // 4: .{ .Normal = { 0, 0, -1 }, .Up = { 0, 1, 0 }, .Right = { 1, 0, 0 } }
                        // 4: .{ .up = 3, .down = 1, .left = 2, .right = 5 }
                        // 5: .{ .Normal = { -1, 0, 0 }, .Up = { 0, 1, 0 }, .Right = { 0, 0, -1 } }
                        // 5: .{ .up = 3, .down = 1, .left = 4, .right = 0 }
                        while (true) {
                            frontier = frontier.sub(new_dir);
                            const elem = face[next_id].get(@intCast(frontier.re), @intCast(frontier.im));
                            if (elem == ' ') break;
                        }
                        frontier = frontier.add(new_dir);
                        if (face[next_id].get(@intCast(frontier.re), @intCast(frontier.im)) == '#') break;
                        direction = new_dir;
                        position = frontier;
                        id = next_id;
                    },
                }
            },
        }
    }
    std.debug.print("{any}\n", .{id});
    std.debug.print("{any}\n", .{position});
    std.debug.print("{any}\n", .{direction});
    const score: CT = if (direction.re == 0) @as(CT, if (direction.im == 1) 0 else 2) else if (direction.im == 1) 1 else 3;
    return 1000 * position.re + 4 * position.im + score;
}
