const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
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

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    const input = @embedFile("in/d19.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var in_iter = std.mem.tokenizeSequence(u8, input, double_delim);

    const raw_towel_patterns = in_iter.next().?;
    const raw_desire = in_iter.next().?;

    var patterns = Patterns.init(allocator);
    defer patterns.deinit();

    var patterns_iter = std.mem.tokenizeSequence(u8, raw_towel_patterns, ", ");
    while (patterns_iter.next()) |pattern| try patterns.put(pattern, {});

    var sum: u64 = 0;
    var sum2: u64 = 0;

    var memo = Memo.init(allocator);
    defer memo.deinit();

    var desire_iter = std.mem.tokenizeSequence(u8, raw_desire, input_attributes.delim);
    while (desire_iter.next()) |desire| {
        var early_exit = false;
        if (part1(desire, &[0]u8{}, patterns, @truncate(0), @truncate(desire.len), &early_exit)) {
            sum += 1;
        }
        defer memo.clearRetainingCapacity();
        const res = try part2(desire, &[0]u8{}, patterns, @truncate(0), @truncate(desire.len), &memo);
        // printa(res);
        sum2 += res;
    }
    // too low 55093
    printa(sum);
    printa(sum2);
}

const Patterns = std.StringArrayHashMap(void);
const Towel = myf.FixedBuffer(u8, 8);
const Hasher = std.hash.XxHash32;

const HashCtx = struct {
    pub fn hash(_: @This(), key: Key) u32 {
        return @bitCast([2]u16{ key.strlen, key.index });
    }
    pub fn eql(_: @This(), a: Key, b: Key, _: usize) bool {
        return a.strlen == b.strlen and a.index == b.index;
    }
};

const Memo = std.ArrayHashMap(Key, u64, HashCtx, true);

const Key = struct {
    // str: []const u8,
    strlen: u16,
    index: u16,
};

fn part1(str: []const u8, built_towel: []const u8, patterns: Patterns, index: u8, max_len: u8, early_exit: *bool) bool {
    if (early_exit.*) return true;
    if (index == max_len) {
        if (std.mem.eql(u8, str, built_towel)) {
            early_exit.* = true;
            return true;
        }
        return false;
    }
    var disjunct: bool = false;
    for (index + 1..max_len + 1) |i| {
        if (patterns.contains(str[index..i])) {
            disjunct = disjunct or part1(str, str[0..i], patterns, @intCast(i), max_len, early_exit);
        }
    }

    return disjunct;
}

fn part2(str: []const u8, built_towel: []const u8, patterns: Patterns, index: u8, max_len: u8, memo: *Memo) !u64 {
    if (index == max_len) {
        if (std.mem.eql(u8, str, built_towel)) {
            return 1;
        }
        return 0;
    }
    var sum: u64 = 0;
    for (index + 1..max_len + 1) |i| {
        const key: Key = .{ .index = index, .strlen = @intCast(i - index) };
        if (memo.*.get(key)) |res| {
            sum += res;
            continue;
        }
        if (patterns.contains(str[index..i])) {
            const res = try part2(str, str[0..i], patterns, @intCast(i), max_len, memo);
            try memo.*.put(key, res);
            sum += res;
        }
    }

    return sum;
}

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d19.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var in_iter = std.mem.tokenizeSequence(u8, input, double_delim);

    const raw_towel_patterns = in_iter.next().?;
    const raw_desire = in_iter.next().?;

    var patterns = Patterns.init(allocator);
    defer patterns.deinit();

    var patterns_iter = std.mem.tokenizeSequence(u8, raw_towel_patterns, ", ");
    while (patterns_iter.next()) |pattern| try patterns.put(pattern, {});

    var sum: u64 = 0;
    var sum2: u64 = 0;

    var desire_iter = std.mem.tokenizeSequence(u8, raw_desire, input_attributes.delim);
    while (desire_iter.next()) |desire| {
        var early_exit = false;
        if (part1(desire, &[0]u8{}, patterns, @truncate(0), @truncate(desire.len), &early_exit)) {
            sum += 1;
        }
        sum2 += part2(desire, &[0]u8{}, patterns, @truncate(0), @truncate(desire.len));
        printa(sum2);
    }
    printa(sum);
    printa(sum2);
}
