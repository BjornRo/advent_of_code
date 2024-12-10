const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const CT = i8;
const ComplexT = std.math.Complex(CT);
const F = struct {
    inline fn inBounds(pos: ComplexT, max_row: CT, max_col: CT) bool {
        return 0 <= pos.re and pos.re < max_row and 0 <= pos.im and pos.im < max_col;
    }
    inline fn u16_to_complex(n: u16) ComplexT {
        const res: [2]CT = @bitCast(n);
        return ComplexT{ .re = res[0], .im = res[1] };
    }
    inline fn castComplexT(c: ComplexT) [2]u8 {
        return .{ @bitCast(c.re), @bitCast(c.im) };
    }
};

const HashCtx = struct {
    pub fn hash(_: @This(), key: ComplexT) u16 {
        return @bitCast([2]CT{ key.re, key.im });
    }
    pub fn eql(_: @This(), a: ComplexT, b: ComplexT, _: usize) bool {
        return a.re == b.re and a.im == b.im;
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
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    // const allocator = gpa.allocator();
    var buffer: [5_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input = @embedFile("in/d10.txt");
    // End setup

    const input_attributes = try myf.getInputAttributes(input);

    // Assuming square matrix
    const dimension: u8 = @intCast(input_attributes.row_len);
    const matrix = try allocator.alloc([]const u8, dimension);
    defer allocator.free(matrix);

    var start_pos = std.ArrayList(ComplexT).init(allocator);
    defer start_pos.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    for (matrix, 0..) |*row, i| {
        if (in_iter.next()) |data| row.* = data;
        for (row.*, 0..) |e, j| {
            if (e == '0') try start_pos.append(ComplexT.init(@intCast(i), @intCast(j)));
        }
    }

    var trailheads = std.ArrayHashMap(ComplexT, void, HashCtx, true).init(allocator);
    defer trailheads.deinit();
    try trailheads.ensureTotalCapacity(8);

    var p1_sum: u16 = 0;
    var p2_sum: u16 = 0;
    for (start_pos.items) |s| {
        p1_sum += dfsRec(matrix, @intCast(dimension), &trailheads, s, '0');
        p2_sum += @intCast(trailheads.count());
        trailheads.clearRetainingCapacity();
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}

fn dfsRec(
    matrix: []const []const u8,
    dimension: CT,
    trailheads: *std.ArrayHashMap(ComplexT, void, HashCtx, true),
    position: ComplexT,
    current_val: u8,
) u8 {
    if (!F.inBounds(position, dimension, dimension)) return 0;
    const row, const col = F.castComplexT(position);
    const curr_pos = matrix[row][col];
    if (curr_pos != current_val) return 0;
    if (curr_pos == '9') {
        trailheads.putAssumeCapacity(position, {});
        return 1;
    }

    const rot_right = ComplexT.init(0, -1);
    var direction = ComplexT.init(0, 1);
    var sum: u8 = dfsRec(matrix, dimension, trailheads, position.add(direction), current_val + 1);
    inline for (0..3) |_| {
        direction = direction.mul(rot_right);
        sum += dfsRec(matrix, dimension, trailheads, position.add(direction), current_val + 1);
    }
    return sum;
}
