const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const WIDTH = 25;
const HEIGHT = 6;
const Vec25 = @Vector(WIDTH, u8);

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [70_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

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

    try writer.print("Part 1: {d}\nPart 2:\n\n", .{part1(&layers)});
    var image: [HEIGHT][WIDTH]u8 = undefined;
    var rev_it = std.mem.reverseIterator(layers);
    while (rev_it.next()) |layer| {
        for (layer, 0..) |row, i| {
            for (0..WIDTH) |j| {
                if (row[j] != 2) image[i][j] = if (row[j] == 0) ' ' else '#';
            }
        }
    }
    for (image) |row| try writer.print("  {s}\n", .{row});
}

fn part1(image: *const []const [6]Vec25) u16 {
    var min_zeroes: u8 = 255;
    var min_layer: u8 = 0;
    for (0..image.len) |i| {
        var total_zeroes: u8 = 0;
        for (0..HEIGHT) |j|
            total_zeroes += std.simd.countElementsWithValue(image.*[i][j], 0);
        if (total_zeroes < min_zeroes) {
            min_zeroes = total_zeroes;
            min_layer = @intCast(i);
        }
    }
    var total_ones: u16 = 0;
    var total_twos: u16 = 0;
    for (image.*[min_layer]) |row| {
        total_ones += @intCast(std.simd.countElementsWithValue(row, 1));
        total_twos += @intCast(std.simd.countElementsWithValue(row, 2));
    }
    return total_ones * total_twos;
}
