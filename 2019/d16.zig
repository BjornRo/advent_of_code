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
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

fn FFT(allocator: Allocator, values: []const i16, phase: u32) ![]i16 {
    var output = try allocator.alloc(i16, values.len);
    @memcpy(output, values);

    var iter_arr = try allocator.alloc(i16, values.len);
    defer allocator.free(iter_arr);

    const pattern: []const i8 = &[_]i8{ 0, 1, 0, -1 };

    for (0..phase) |_| {
        for (1..output.len + 1) |iter| {
            var pidx: u8 = 0;
            var sum: i16 = 0;
            var skip_first = true;

            var oidx: u16 = 0;
            outer: while (true) {
                for (0..iter) |_| {
                    if (skip_first) {
                        skip_first = false;
                        continue;
                    }
                    sum += output[oidx] * pattern[pidx];
                    oidx += 1;
                    if (oidx >= output.len) break :outer;
                }
                pidx = @mod(pidx + 1, 4);
            }
            if (sum < 0) sum = -sum;
            iter_arr[iter - 1] = @mod(sum, 10);
        }
        const tmp = output;
        output = iter_arr;
        iter_arr = tmp;
    }
    return output;
}

fn part1(allocator: Allocator, values: []const i16, phase: u32) ![8]u8 {
    var return_value: [8]u8 = undefined;
    const output = try FFT(allocator, values, phase);
    defer allocator.free(output);

    for (0..return_value.len) |i| return_value[i] = @intCast(output[i] + '0');
    return return_value;
}

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d16.txt");

    const input_trim = std.mem.trimRight(u8, input, "\r\n");

    var values = try allocator.alloc(i16, input_trim.len);
    defer allocator.free(values);
    for (input_trim, 0..) |v, i| values[i] = @intCast(v - '0');

    prints(try part1(allocator, values, 100));
}
