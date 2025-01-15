const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    // const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    // std.debug.print("{s}\n", .{input});
    // std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

const WIDTH = 25;
const HEIGHT = 6;
const PIXELS = WIDTH * HEIGHT;

const Vec25 = @Vector(25, u8);

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d08.txt");
    const input_attributes = try myf.getInputAttributes(input);
    const loops = input_attributes.row_len / WIDTH;
    const n_layers = loops / HEIGHT;

    const layers = try allocator.alloc([HEIGHT]Vec25, n_layers);
    defer allocator.free(layers);

    var index: usize = 0;
    for (0..n_layers) |i| {
        for (0..HEIGHT) |j| {
            const row: Vec25 = input[index .. index + WIDTH][0..WIDTH].*;
            layers[i][j] = row - @as(Vec25, @splat('0'));
            index += WIDTH;
        }
    }
    var min_zeroes: u8 = 255;
    var min_layer: u8 = 0;
    for (0..n_layers) |i| {
        var total_zeroes: u8 = 0;
        for (0..HEIGHT) |j| total_zeroes += std.simd.countElementsWithValue(layers[i][j], 0);
        if (total_zeroes < min_zeroes) {
            min_zeroes = total_zeroes;
            min_layer = @intCast(i);
        }
    }
    var total_ones: u8 = 0;
    var total_twos: u8 = 0;
    for (0..HEIGHT) |i| {
        const row = layers[min_layer][i];
        total_ones += std.simd.countElementsWithValue(row, 1);
        total_twos += std.simd.countElementsWithValue(row, 2);
    }
    print(total_ones);
    print(total_twos);
}
