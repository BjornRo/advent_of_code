const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const Patterns = std.StringArrayHashMap(void);

fn part1(str: []const u8, patterns: Patterns, index: u8, max_len: u8, early_exit: *bool) bool {
    if (early_exit.*) return true;
    if (index == max_len) {
        early_exit.* = true;
        return true;
    }
    for (index + 1..max_len + 1) |i| {
        if (patterns.contains(str[index..i])) {
            if (part1(str, patterns, @intCast(i), max_len, early_exit))
                return true;
        }
    }
    return false;
}

fn part2(str: []const u8, patterns: Patterns, index: u8, max_len: u8, memo: *[61][61]?u64) !u64 {
    if (index >= max_len) return 1;

    var sum: u64 = 0;
    for (index + 1..max_len + 1) |i| {
        if (memo[index][@intCast(i - index)]) |result| {
            sum += result;
            continue;
        }
        if (patterns.contains(str[index..i])) {
            const res = try part2(str, patterns, @intCast(i), max_len, memo);
            memo[index][@intCast(i - index)] = res;
            sum += res;
        }
    }

    return sum;
}
pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [130_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var in_iter = std.mem.tokenizeSequence(u8, input, double_delim);

    const raw_towel_patterns = in_iter.next().?;
    const raw_desire = in_iter.next().?;

    var patterns = Patterns.init(allocator);
    defer patterns.deinit();

    var patterns_iter = std.mem.tokenizeSequence(u8, raw_towel_patterns, ", ");
    while (patterns_iter.next()) |pattern| try patterns.put(pattern, {});

    var p1_sum: u16 = 0;
    var p2_sum: u64 = 0;

    const raw_memo = try myf.initValueSlice(allocator, 61 * 61, @as(?u64, null));
    defer allocator.free(raw_memo);
    const mmemo = @as(*[61][61]?u64, @ptrCast(raw_memo));

    var desire_iter = std.mem.tokenizeSequence(u8, raw_desire, input_attributes.delim);
    while (desire_iter.next()) |desire| {
        var early_exit = false;
        if (part1(desire, patterns, @truncate(0), @truncate(desire.len), &early_exit))
            p1_sum += 1;

        var memo = mmemo.*;
        p2_sum += try part2(desire, patterns, @truncate(0), @truncate(desire.len), &memo);
    }
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}
