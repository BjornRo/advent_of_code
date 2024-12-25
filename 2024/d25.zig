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

const Vec5 = @Vector(5, u8);
pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [40_000]u8 = undefined;
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

    var locks = std.ArrayList(Vec5).init(allocator);
    var keys = std.ArrayList(Vec5).init(allocator);
    defer inline for (.{ locks, keys }) |l| l.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, double_delim);
    while (in_iter.next()) |sub_mat| {
        const result = parseSubMat(sub_mat, input_attributes.delim);
        const list = if (result.is_lock) &locks else &keys;
        try list.*.append(result.vector);
    }

    try writer.print("Part 1: {d}", .{combinations(locks.items, keys.items)});
}

fn combinations(locks: []Vec5, keys: []Vec5) u16 {
    var pairs: u16 = 0;
    for (locks) |lock| {
        for (keys) |key| {
            const res: [5]bool = (lock + key) > Vec5{ 5, 5, 5, 5, 5 };
            if (!myf.any(&res)) {
                pairs += 1;
            }
        }
    }
    return pairs;
}

fn parseSubMat(sub_mat: []const u8, delim: []const u8) struct { is_lock: bool, vector: Vec5 } {
    var vector: Vec5 = @splat(0);

    var is_lock = false;
    var sub_mat_it = std.mem.tokenizeSequence(u8, sub_mat, delim);

    var first_row = false;
    var rows: u8 = 0;
    while (sub_mat_it.next()) |row| {
        defer rows += 1;
        if (!first_row) {
            first_row = true;
            is_lock = row[0] == '#';
            continue;
        }
        var row_vec: Vec5 = undefined;
        for (row, 0..) |c, i| row_vec[i] = c;

        vector += row_vec & Vec5{ 1, 1, 1, 1, 1 }; // "." ends with 0, "#" with 1 :)
        if (rows == 5) break;
    }
    return .{ .is_lock = is_lock, .vector = vector };
}
