const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

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

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    var p1_sum: u64 = 0;

    var list = std.ArrayList(u64).init(allocator);
    defer list.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        const seed = try std.fmt.parseInt(u64, row, 10);
        p1_sum += part1(seed);
        try list.append(seed);
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, try part2(allocator, list.items) });
}

fn part2(allocator: Allocator, seeds: []u64) !i64 {
    var map = std.AutoArrayHashMap([4]i8, i16).init(allocator);
    defer map.deinit();

    var visited = std.AutoArrayHashMap([4]i8, void).init(allocator);
    defer visited.deinit();
    try visited.ensureTotalCapacity(2000);

    var first_index = myf.FixedBuffer([4]i8, 2000).init();
    var list = myf.FixedBuffer(i8, 2000).init();

    for (seeds, 0..) |seed, i| {
        list.len = 0;
        visited.clearRetainingCapacity();

        var secret = seed;

        var prev: i8 = @intCast(@mod(secret, 10));
        for (0..2000) |j| {
            secret = prng(secret);
            const curr: i8 = @intCast(@mod(secret, 10));
            const delta = curr - prev;

            try list.append(delta);

            const slice = list.getSlice();
            if (slice.len >= 4) {
                const arr: [4]i8 = .{ slice[j - 3], slice[j - 2], slice[j - 1], slice[j] };
                if (!visited.contains(arr)) {
                    visited.putAssumeCapacity(arr, {});

                    const res = try map.getOrPut(arr);
                    if (!res.found_existing) {
                        res.value_ptr.* = 0;
                    }
                    res.value_ptr.* += curr;
                    if (i == 0) try first_index.append(arr);
                }
            }
            prev = curr;
        }
    }

    var max: i16 = 0;
    for (first_index.getSlice()) |k| {
        const value = map.get(k).?;
        if (value > max) max = value;
    }
    return max;
}

fn part1(seed: u64) u64 {
    var secret = seed;
    for (0..2000) |_| secret = prng(secret);
    return secret;
}

fn prng(seed: u64) u64 {
    var secret = seed;
    secret ^= secret * 64;
    secret = @mod(secret, 16777216);
    secret ^= secret / 32;
    secret = @mod(secret, 16777216);
    secret ^= secret * 2048;
    secret = @mod(secret, 16777216);
    return secret;
}
