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
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

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

test "example" {
    const allocator = std.testing.allocator;

    const input = @embedFile("in/d22.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var p1_sum: u64 = 0;

    var list = std.ArrayList(u64).init(allocator);
    defer list.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        const seed = try std.fmt.parseInt(u64, row, 10);
        p1_sum += part1(seed);
        try list.append(seed);
    }
    printa(p1_sum);

    _ = try part2(allocator, list.items);
}

const Tuple = struct {
    value: i64,
    index: u16,

    const Self = @This();

    fn lessThan(_: void, a: Self, b: Self) bool {
        return a.index < b.index;
    }
};

fn part2(allocator: Allocator, seeds: []u64) !i64 {
    var map = std.AutoArrayHashMap([4]i8, std.ArrayList(Tuple)).init(allocator);
    defer {
        for (map.values()) |v| v.deinit();
        map.deinit();
    }

    for (seeds, 0..) |seed, i| {
        var queue = try Deque(i8).init(allocator);
        defer queue.deinit();
        var sub_map = std.AutoArrayHashMap([4]i8, Tuple).init(allocator);
        defer sub_map.deinit();
        var secret = seed;

        var prev: i8 = @intCast(@mod(secret, 10));
        for (0..2000) |_| {
            secret = prng(secret);
            const curr: i8 = @intCast(@mod(secret, 10));
            const delta = curr - prev;

            try queue.pushBack(delta);
            if (queue.len() == 5) _ = queue.popFront().?;

            if (queue.len() == 4) {
                var buf = myf.FixedBuffer(i8, 4).init();

                var iter = queue.iterator();
                while (iter.next()) |val| try buf.append(val.*);
                if (!sub_map.contains(buf.buf)) {
                    try sub_map.put(buf.buf, Tuple{ .index = @intCast(i), .value = curr });
                }
            }
            prev = curr;
        }
        var iter = sub_map.iterator();
        while (iter.next()) |kv| {
            const res = try map.getOrPut(kv.key_ptr.*);
            if (!res.found_existing) {
                res.value_ptr.* = std.ArrayList(Tuple).init(allocator);
            }
            try res.value_ptr.*.append(kv.value_ptr.*);
        }
    }

    var banana_tree = std.ArrayList(i64).init(allocator);
    defer banana_tree.deinit();
    for (map.values()) |k| {
        var sum: i64 = 0;
        var index: u16 = 4000;
        for (k.items) |val| {
            sum += val.value;
            if (val.index < index) {
                index = val.index;
            }
        }

        if (index != 0) continue;
        try banana_tree.append(sum);
    }
    std.mem.sort(i64, banana_tree.items, {}, std.sort.desc(i64));
    return banana_tree.items[0];
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
