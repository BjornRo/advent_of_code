const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

fn FFT(allocator: Allocator, values: []const i32, phase: u32) ![]i32 {
    var output = try allocator.alloc(i32, values.len);
    @memcpy(output, values);

    var iter_arr = try allocator.alloc(i32, values.len);
    defer allocator.free(iter_arr);

    const pattern: []const i8 = &[_]i8{ 0, 1, 0, -1 };

    for (0..phase) |_| {
        for (1..output.len + 1) |iter| {
            var pidx: u8 = 0;
            var sum: i32 = 0;
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

fn part1(allocator: Allocator, values: []const i32, phase: u32) ![8]u8 {
    var return_value: [8]u8 = undefined;
    const output = try FFT(allocator, values, phase);
    defer allocator.free(output);

    for (0..return_value.len) |i| return_value[i] = @intCast(output[i] + '0');
    return return_value;
}

fn part2(allocator: Allocator, values: []const i32, speedup_fac: u8) ![8]u8 {
    const msg_offset = blk: {
        var offset: u32 = 0;
        for (values[0..7]) |v| {
            offset *= 10;
            offset += @intCast(v);
        }
        break :blk offset;
    };

    var output = try allocator.alloc(i32, values.len * 10_000);
    defer allocator.free(output);
    for (0..output.len) |i| output[i] = values[i % values.len];

    var iter_arr = try allocator.alloc(i32, output.len);
    defer allocator.free(iter_arr);

    for (0..100) |_| {
        var cumsum: i32 = 0;
        for (0..output.len / speedup_fac) |i| {
            const j = output.len - i - 1;
            cumsum += output[j];
            iter_arr[j] = @mod(cumsum, 10);
        }
        const tmp = output;
        output = iter_arr;
        iter_arr = tmp;
    }

    var return_value: [8]u8 = undefined;
    for (output[msg_offset .. msg_offset + 8], 0..) |v, i| return_value[i] = @intCast(v + '0');
    return return_value;
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    const input_trim = std.mem.trimRight(u8, input, "\r\n");

    var values = try allocator.alloc(i32, input_trim.len);
    defer allocator.free(values);
    for (input_trim, 0..) |v, i| values[i] = @intCast(v - '0');

    try writer.print("Part 1: {s}\nPart 2: {s}\n", .{
        try part1(allocator, values, 100),
        try part2(allocator, values, 12), // adjust until it gives correct result
    });
}
