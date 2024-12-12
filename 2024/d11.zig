const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const print = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const Tuple = packed struct {
    value: u40,
    iter: u8,
    // max value 409526509568, 39 bits
    const HashCtx = struct {
        pub fn hash(_: @This(), key: Tuple) u32 {
            const iter_shifted = @as(u64, @intCast(key.iter)) << 32;
            const combined = iter_shifted | key.value;
            const prime = 0x9e3779b1;

            var _hash: u128 = combined ^ (combined >> 32);
            _hash = _hash * prime;
            _hash = _hash ^ (_hash >> 29);
            return @truncate(_hash);
        }
        pub fn eql(_: @This(), a: Tuple, b: Tuple, _: usize) bool {
            return a.value == b.value and a.iter == b.iter;
        }
    };
};

const Map = std.ArrayHashMap(Tuple, u64, Tuple.HashCtx, true);

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [6_000_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);

    var list = try std.ArrayList(u64).initCapacity(allocator, 10);
    defer list.deinit();

    var in_iter = std.mem.splitScalar(u8, input[0..(try myf.getInputAttributes(input)).row_len], ' ');
    while (in_iter.next()) |elem| list.appendAssumeCapacity(try std.fmt.parseInt(u64, elem, 10));

    var memo = Map.init(allocator);
    try memo.ensureTotalCapacity(125000);
    defer memo.deinit();

    var p1_sum: u64 = 0;
    var p2_sum: u64 = 0;
    for (list.items) |item| p1_sum += recIter(25, 0, &.{item}, &memo);
    memo.clearRetainingCapacity();
    for (list.items) |item| p2_sum += recIter(75, 0, &.{item}, &memo);

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}

fn recIter(max_iter: u8, iter: u8, slice: []const u64, memo: *Map) u64 {
    if (max_iter == iter) return slice.len;

    var sum: u64 = 0;
    var res: u64 = 0;
    for (slice) |item| {
        if (memo.get(.{ .iter = iter, .value = @truncate(item) })) |val| {
            sum += val;
            continue;
        }
        if (item == 0) {
            res = recIter(max_iter, iter + 1, &.{1}, memo);
        } else {
            const digits = std.math.log10_int(item);
            if (@mod(digits, 2) == 1) { // Add 1 digit later, "optimization"
                const pow = std.math.powi(u64, 10, @divExact(digits + 1, 2)) catch unreachable;
                res = recIter(max_iter, iter + 1, &.{ @divFloor(item, pow), @mod(item, pow) }, memo);
            } else {
                res = recIter(max_iter, iter + 1, &.{item * 2024}, memo);
            }
        }
        sum += res;
        memo.*.putAssumeCapacity(.{ .iter = iter, .value = @truncate(item) }, res);
    }
    return sum;
}
