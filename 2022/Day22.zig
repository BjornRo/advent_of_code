const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const CT = i32;
const Complex = std.math.complex.Complex(CT);
const Instruction = union(enum) {
    value: u8,
    rotation: enum { Right, Left },
};

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

fn solve(alloc: Allocator, data: []u8) !struct { p1: usize, p2: usize } {
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

    var map = utils.arrayToMatrix(data[0..split_index]);
    return .{ .p1 = try part1(alloc, &map, instructions), .p2 = 2 };
}
const leftRotation = Complex.init(0, 1);
const rightRotation = Complex.init(0, -1);

fn part1(alloc: Allocator, map: *utils.Matrix, instructions: []Instruction) !usize {
    var visited: std.AutoHashMap(Complex, Complex) = .init(alloc);
    defer visited.deinit();

    var position: Complex = for (0..map.cols) |i| {
        if (map.get(0, i) == '.') break .init(0, @intCast(i));
    } else unreachable;

    var direction = Complex.init(0, 1); // Right

    direction.re = 0;
    position.re = 0;

    for (instructions) |ins| {
        switch (ins) {
            .rotation => |r| direction = direction.mul(switch (r) {
                .Left => leftRotation,
                .Right => rightRotation,
            }),
            .value => |v| {
                try visited.put(position, direction);
                for (0..v) |_| {
                    const next_position = position.add(direction);
                    if (!map.inBounds(next_position.re, next_position.im)) {
                        position.re = @mod(position.re, @as(CT, @intCast(map.rows)));
                        position.im = @mod(position.im, @as(CT, @intCast(map.cols)));
                        map.set(@intCast(position.re), @intCast(position.im), 'o');
                    } else switch (map.get(@intCast(next_position.re), @intCast(next_position.im))) {
                        ' ' => {
                            var frontier = position;
                            while (true) {
                                frontier = frontier.sub(direction);
                                if (!map.inBounds(frontier.re, frontier.im)) break;
                                const elem = map.get(@intCast(frontier.re), @intCast(frontier.im));
                                if (elem == ' ') break;
                            }
                            position = frontier.add(direction);
                            map.set(@intCast(position.re), @intCast(position.im), 'o');
                        },
                        '.' => {
                            position = next_position;
                            map.set(@intCast(position.re), @intCast(position.im), 'o');
                        },
                        else => {}, // "#", do nothing
                    }
                }
            },
        }
    }
    map.print('x');
    std.debug.print("{any}\n", .{position});
    std.debug.print("{any}\n", .{direction});
    return 1;
}
