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

const VisitedT = std.AutoArrayHashMap(u32, ComplexT);
const rotations = [3]ComplexT{ ComplexT.init(1, 0), rot_left, rot_right };
const State = struct {
    count: u32,
    pos: ComplexT,
    dir: ComplexT,

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
    const input = @embedFile("in/d16t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const matrix = try allocator.alloc([]const u8, input_attributes.row_len);
    defer allocator.free(matrix);

    var grid_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    for (matrix) |*row| row.* = grid_iter.next().?;

    // const start_pos = ComplexT{ .re = matrix.len - 1, .im = 1 };
    // var dir = ComplexT{ .re = 0, .im = 1 }; // Facing east

    const mat = try myf.initValueMatrix(allocator, 10, 10, false);
    defer myf.freeMatrix(allocator, mat);

    var pqueue = PriorityQueue(State, void, State.cmp).init(allocator, undefined);
    defer pqueue.deinit();
    try pqueue.add(.{
        .pos = ComplexT{ .re = @intCast(matrix.len - 2), .im = 1 },
        .dir = ComplexT{ .re = 0, .im = 1 }, // Facing east
        .count = 0,
    });

    var visited = try myf.initValueMatrix(allocator, matrix.len, matrix[0].len, false);
    defer myf.freeMatrix(allocator, visited);
    var distances = try myf.initValueMatrix(allocator, matrix.len, matrix[0].len, @as(u32, std.math.maxInt(u32)));
    defer myf.freeMatrix(allocator, distances);

    var min_distance: u32 = std.math.maxInt(u32);
    while (pqueue.items.len != 0) {
        var state = pqueue.remove();

        if (finish(matrix, state.pos)) {
            const row, const col = complexToUInt(state.pos);
            min_distance = distances[row][col];
            break;
        }
        const row, const col = complexToUInt(state.pos);
        if (visited[row][col]) continue;
        visited[row][col] = true;

        for (rotations, 0..) |rot, i| {
            const new_rotation = state.dir.mul(rot);
            const next_step = state.pos.add(new_rotation);
            if (!inBounds(matrix, next_step)) continue;

            const next_row, const next_col = complexToUInt(next_step);
            var new_cost: u32 = if (i == 0) 0 else 1000;
            new_cost += state.count + 1;

            if (new_cost >= distances[next_row][next_col]) continue;
            distances[next_row][next_col] = new_cost;
            try pqueue.add(.{
                .count = new_cost,
                .pos = next_step,
                .dir = new_rotation,
            });
        }
    }
    printa(min_distance);
}

fn inBounds(matrix: []const []const u8, complex: ComplexT) bool {
    const row, const col = complexToUInt(complex);
    return matrix[row][col] != '#';
}

fn finish(matrix: []const []const u8, complex: ComplexT) bool {
    const row, const col = complexToUInt(complex);
    return matrix[row][col] == 'E';
}

fn complexToUInt(c: ComplexT) [2]u16 {
    return .{ @bitCast(c.re), @bitCast(c.im) };
}

fn u32ToComplex(n: u32) ComplexT {
    const res: [2]CT = @bitCast(n);
    return ComplexT.init(res[0], res[1]);
}

fn posToU32(pos: ComplexT) u32 {
    return @bitCast([2]i16{ pos.re, pos.im });
}

pub fn eql(a: ComplexT, b: ComplexT) bool {
    return a.re == b.re and a.im == b.im;
}

fn printPath(alloc: Allocator, matrix: []const []const u8, visited: VisitedT) void {
    var new_matrix = myf.copyMatrix(alloc, matrix) catch unreachable;
    defer myf.freeMatrix(alloc, new_matrix);

    for (visited.keys()) |key| {
        const pos = u32ToComplex(key);
        const dir = visited.get(key).?;
        const row, const col = complexToUInt(pos);
        const arrow: u8 = if (eql(dir, ComplexT.init(0, 1)))
            '>'
        else if (eql(dir, ComplexT.init(0, -1)))
            '<'
        else if (eql(dir, ComplexT.init(-1, 0)))
            '^'
        else
            'v';
        new_matrix[row][col] = arrow;
    }

    myf.printMatStr(new_matrix);
}
