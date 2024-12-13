const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;
const Op = std.builtin.ReduceOp;

const T = f64;
const Vec2 = @Vector(2, T);
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
    var buffer: [22_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    std.debug.print("Input size: {d}\n\n", .{input.len});
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input = @embedFile("in/d13.txt");
    // End setup

    const input_attributes = try myf.getInputAttributes(input);

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var p1_sum: u64 = 0;
    var p2_sum: u64 = 0;

    var in_iter = std.mem.tokenizeSequence(u8, input, double_delim);
    while (in_iter.next()) |game| {
        var game_iter = std.mem.tokenizeSequence(u8, game, input_attributes.delim);
        const a_xy: Vec2 = getRowXY(game_iter.next().?);
        const b_xy: Vec2 = getRowXY(game_iter.next().?);
        const XY = getPriceXY(game_iter.next().?);

        const AB_X = Vec2{ a_xy[0], b_xy[0] };
        const AB_Y = Vec2{ a_xy[1], b_xy[1] };

        p1_sum += solve(a_xy, b_xy, AB_X, AB_Y, XY, 0);
        p2_sum += solve(a_xy, b_xy, AB_X, AB_Y, XY, 10000000000000);
    }
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}

fn solve(a: Vec2, b: Vec2, ab_x: Vec2, ab_y: Vec2, XY: Vec2, offset: T) u64 {
    const TokenCost = Vec2{ 3, 1 };
    const X, const Y = XY + Vec2{ offset, offset };
    const res = @floor(solveEquation(a, b, X, Y));
    if (@reduce(Op.Add, ab_x * res) == X and @reduce(Op.Add, ab_y * res) == Y) {
        return @intFromFloat(@reduce(Op.Add, res * TokenCost));
    }
    return 0;
}

fn solveEquation(a_xy: Vec2, b_xy: Vec2, X: T, Y: T) Vec2 {
    const a1 = a_xy[0];
    const a2 = a_xy[1];
    const b1 = b_xy[0];
    const b2 = b_xy[1];

    const det = a1 * b2 - a2 * b1;

    const x = (X * b2 - Y * b1) / det;
    const y = (a1 * Y - a2 * X) / det;

    return Vec2{ x, y };
}

fn getRowXY(row: []const u8) Vec2 {
    var start = std.mem.indexOfScalar(u8, row, '+').? + 1;
    const end = std.mem.indexOfScalar(u8, row, ',').?;
    const x = std.fmt.parseFloat(T, row[start..end]) catch unreachable;

    start = std.mem.lastIndexOfScalar(u8, row, '+').? + 1;
    const y = std.fmt.parseFloat(T, row[start..row.len]) catch unreachable;
    return Vec2{ x, y };
}

fn getPriceXY(row: []const u8) Vec2 {
    var start = std.mem.indexOfScalar(u8, row, '=').? + 1;
    const end = std.mem.indexOfScalar(u8, row, ',').?;
    const x = std.fmt.parseFloat(T, row[start..end]) catch unreachable;

    start = std.mem.lastIndexOfScalar(u8, row, '=').? + 1;
    const y = std.fmt.parseFloat(T, row[start..row.len]) catch unreachable;
    return Vec2{ x, y };
}
