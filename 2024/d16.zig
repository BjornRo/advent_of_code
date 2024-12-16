const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const PriorityQueue = std.PriorityQueue;
const time = std.time;
const Allocator = std.mem.Allocator;

const CT = i16;
const ComplexT = std.math.Complex(CT);
const rot_right = ComplexT.init(0, -1);
const rot_left = ComplexT.init(0, 1);

const HashCtx = struct {
    pub fn hash(_: @This(), key: ComplexT) u32 {
        return @bitCast([2]CT{ key.re, key.im });
    }
    pub fn eql(_: @This(), a: ComplexT, b: ComplexT, _: usize) bool {
        return a.re == b.re and a.im == b.im;
    }
};

const VisitedT = std.ArrayHashMap(ComplexT, u32, HashCtx, true);
const rotations = [3]ComplexT{ ComplexT.init(1, 0), rot_left, rot_right };
const State = struct {
    count: u32,
    pos: ComplexT,
    dir: ComplexT,
    steps: u32,

    const Self = @This();

    fn cmp(_: void, a: Self, b: Self) std.math.Order {
        if (a.count < b.count) return .lt;
        if (a.count > b.count) return .gt;
        return .eq;
    }
};

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    // std.debug.print("{s}\n", .{input});
    const input = @embedFile("in/d16.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const matrix = try allocator.alloc([]const u8, input_attributes.row_len);
    defer allocator.free(matrix);

    var grid_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    for (matrix) |*row| row.* = grid_iter.next().?;

    const mat = try myf.initValueMatrix(allocator, 10, 10, false);
    defer myf.freeMatrix(allocator, mat);

    var pqueue = PriorityQueue(State, void, State.cmp).init(allocator, undefined);
    defer pqueue.deinit();
    try pqueue.add(.{
        .count = 0,
        .pos = ComplexT{ .re = @intCast(matrix.len - 2), .im = 1 },
        .dir = ComplexT{ .re = 0, .im = 1 }, // Facing east
        .steps = 0,
    });

    var visited = VisitedT.init(allocator);
    defer visited.deinit();
    var distances = VisitedT.init(allocator);
    defer distances.deinit();
    var steps = VisitedT.init(allocator);
    defer steps.deinit();
    var visited_crossings = VisitedT.init(allocator);
    defer visited_crossings.deinit();

    var min_distance: u32 = std.math.maxInt(u32);
    while (pqueue.items.len != 0) {
        var state = pqueue.remove();

        if (finishSymbol(matrix, state.pos, 'E')) {
            min_distance = distances.get(state.pos).?;
            break;
        }
        if (visited.get(state.pos) != null) continue;
        try visited.put(state.pos, 0);

        for (rotations, 0..) |rot, i| {
            const new_rotation = state.dir.mul(rot);
            const next_step = state.pos.add(new_rotation);
            if (!inBounds(matrix, next_step)) continue;

            var new_cost: u32 = if (i == 0) 0 else 1000;
            new_cost += state.count + 1;

            if (new_cost < distances.get(next_step) orelse std.math.maxInt(u32)) {
                const count = visited_crossings.get(next_step) orelse 0;
                try visited_crossings.put(next_step, count + 1);

                try steps.put(next_step, state.steps + 1);

                try distances.put(next_step, new_cost);
                try pqueue.add(.{
                    .count = new_cost,
                    .pos = next_step,
                    .dir = new_rotation,
                    .steps = state.steps + 1,
                });
            } else {
                const count = visited_crossings.get(next_step) orelse 0;
                try visited_crossings.put(next_step, count + 1);
            }
        }
    }
    // printa(min_distance);

    // printa(distances.values());
    // for (distances.values()) |*v| v.* = @mod(v.*, 1000);
    // printa(distances.values());

    var sit_map = VisitedT.init(allocator);
    defer sit_map.deinit();
    try sit_map.put(.{ .re = @intCast(matrix.len - 2), .im = 1 }, 0);
    dfs(
        allocator,
        .{ .re = 1, .im = @intCast(matrix.len - 2) },
        .{ .re = @intCast(matrix.len - 2), .im = 1 },
        steps,
        visited_crossings,
        &sit_map,
    );

    // printa(steps.values());
    // printSitMap(allocator, matrix, sit_map);
    printCostMap(allocator, matrix, distances);
    // printa(sit_map.keys().len);
}

const Tuple = struct {
    value: u32,
    position: ComplexT,

    const Self = @This();

    fn lessThan(_: void, a: Self, b: Self) bool {
        return a.value < b.value;
    }
};

fn dfs(
    allocator: Allocator,
    position: ComplexT,
    finish: ComplexT,
    map: VisitedT,
    visited_crossings: VisitedT,
    sit_map: *VisitedT,
) void {
    if (sit_map.*.get(position) != null) return;
    sit_map.*.put(position, 0) catch unreachable;

    if (eql(position, finish)) {
        return;
    }

    var next_list = std.ArrayList(Tuple).init(allocator);
    defer next_list.deinit();

    var direction = ComplexT.init(0, 1);
    for (0..4) |_| {
        direction = direction.mul(rot_right);
        const next_step = position.add(direction);
        if (map.get(next_step)) |value| {
            next_list.append(.{ .value = value, .position = next_step }) catch unreachable;
        }
    }

    const current_value = map.get(position).?;
    const slice = next_list.items;
    std.mem.sort(Tuple, slice, {}, Tuple.lessThan);
    dfs(allocator, slice[0].position, finish, map, visited_crossings, sit_map);
    if (slice.len > 1 and visited_crossings.get(position) orelse 1 == 2) {
        if (current_value <= map.get(slice[1].position).? + 1)
            dfs(allocator, slice[1].position, finish, map, visited_crossings, sit_map);
    }
}

fn dxfs(allocator: Allocator, position: ComplexT, finish: ComplexT, map: VisitedT, sit_map: *VisitedT) void {
    if (sit_map.*.get(position) != null) return;
    sit_map.*.put(position, 0) catch unreachable;

    if (eql(position, finish)) {
        return;
    }

    var next_steps = std.ArrayList(Tuple).init(allocator);
    defer next_steps.deinit();

    // const current_value = map.get(position).?;

    var direction = ComplexT.init(0, 1);
    for (0..4) |_| {
        direction = direction.mul(rot_right);
        const next_step = position.add(direction);
        if (map.get(next_step)) |value| {
            // if (current_value >= value)
            next_steps.append(.{ .value = value, .position = next_step }) catch unreachable;
        }
    }

    const slice = next_steps.items;

    std.mem.sort(Tuple, slice, {}, Tuple.lessThan);
    dfs(allocator, slice[0].position, finish, map, sit_map);
    // if (slice.len > 1 and slice[0].value + 1 >= slice[1].value)
    // dfs(allocator, slice[1].position, finish, map, sit_map);

    // for (slice) |item| {
    //     if (item.value == slice[0].value) {
    //         dfs(allocator, item.position, finish, map, sit_map);
    //         break;
    //     }
    // }
}

fn printCostMap(alloc: Allocator, matrix: []const []const u8, visited: VisitedT) void {
    // var new_matrix = myf.copyMatrix(alloc, matrix) catch unreachable;
    var new_matrix = myf.initValueMatrix(alloc, matrix.len, matrix[0].len, @as(u32, 0)) catch unreachable;
    defer myf.freeMatrix(alloc, new_matrix);

    for (visited.keys()) |key| {
        const row, const col = complexToUInt(key);
        new_matrix[row][col] = visited.get(key).?;
    }

    const stdout = std.io.getStdOut().writer();

    for (new_matrix) |row| {
        for (row) |e| {
            if (e == 0) {
                stdout.print("#     ", .{}) catch unreachable;
            } else {
                const digits = std.math.log10_int(e);
                switch (digits) {
                    0 => stdout.print("{d}     ", .{e}) catch unreachable,
                    1 => stdout.print("{d}    ", .{e}) catch unreachable,
                    2 => stdout.print("{d}   ", .{e}) catch unreachable,
                    3 => stdout.print("{d}  ", .{e}) catch unreachable,
                    4 => stdout.print("{d} ", .{e}) catch unreachable,
                    5 => stdout.print("{d}", .{e}) catch unreachable,
                    6 => stdout.print("{d}", .{e}) catch unreachable,
                    7 => stdout.print("{d}", .{e}) catch unreachable,
                    else => {},
                }
            }
        }
        stdout.print("\n", .{}) catch unreachable;
    }
}

fn printSitMap(alloc: Allocator, matrix: []const []const u8, visited: VisitedT) void {
    // var new_matrix = myf.copyMatrix(alloc, matrix) catch unreachable;
    var new_matrix = myf.initValueMatrix(alloc, matrix.len, matrix[0].len, @as(u8, '.')) catch unreachable;
    defer myf.freeMatrix(alloc, new_matrix);

    for (visited.keys()) |key| {
        const row, const col = complexToUInt(key);
        new_matrix[row][col] = 'O';
    }

    myf.printMatStr(new_matrix);
}

fn inBounds(matrix: []const []const u8, complex: ComplexT) bool {
    const row, const col = complexToUInt(complex);
    return matrix[row][col] != '#';
}

fn finishSymbol(matrix: []const []const u8, complex: ComplexT, scalar: u8) bool {
    const row, const col = complexToUInt(complex);
    return matrix[row][col] == scalar;
}

fn complexToUInt(c: ComplexT) [2]u16 {
    return .{ @bitCast(c.re), @bitCast(c.im) };
}

pub fn eql(a: ComplexT, b: ComplexT) bool {
    return a.re == b.re and a.im == b.im;
}

// fn printPath(alloc: Allocator, matrix: []const []const u8, visited: VisitedT) void {
//     var new_matrix = myf.copyMatrix(alloc, matrix) catch unreachable;
//     defer myf.freeMatrix(alloc, new_matrix);

//     for (visited.keys()) |key| {
//         const pos = u32ToComplex(key);
//         const dir = visited.get(key).?;
//         const row, const col = complexToUInt(pos);
//         const arrow: u8 = if (eql(dir, ComplexT.init(0, 1)))
//             '>'
//         else if (eql(dir, ComplexT.init(0, -1)))
//             '<'
//         else if (eql(dir, ComplexT.init(-1, 0)))
//             '^'
//         else
//             'v';
//         new_matrix[row][col] = arrow;
//     }

//     myf.printMatStr(new_matrix);
// }
