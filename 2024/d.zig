const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const print = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

// const Tuple = struct {
//     value: u64,
//     iter: u8,
// };

// const HashCtx = struct {
//     pub fn hash(_: @This(), key: Tuple) u128 {
//         return @bitCast([2]u64{ key.value, key.iter });
//     }
//     pub fn eql(_: @This(), a: Tuple, b: Tuple, _: usize) bool {
//         return a.value == b.value and a.iter == b.iter;
//     }
// };

const Map = std.AutoArrayHashMap([2]u64, u64);

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
    const input = "337 42493 1891760 351136 2 6932 73 0\r\n";
    const input_attributes = try myf.getInputAttributes(input);

    var list = try std.ArrayList(u64).initCapacity(
        allocator,
        @intCast(1 + std.mem.count(u8, input[0..input_attributes.row_len], " ")),
    );
    defer list.deinit();

    var in_iter = std.mem.splitScalar(u8, input[0..input_attributes.row_len], ' ');
    while (in_iter.next()) |elem| {
        list.appendAssumeCapacity(try std.fmt.parseInt(u64, elem, 10));
    }

    var memo = Map.init(allocator);
    defer memo.deinit();

    var sum: u64 = 0;
    var list2 = std.ArrayList(u64).init(allocator);
    defer list2.deinit();
    for (list.items) |item| {
        sum += recIter(allocator, 75, 0, &.{item}, &memo);
    }
    print(sum);
}

fn recIter(alloc: Allocator, max_iter: u64, iter: u64, slice: []const u64, memo: *Map) u64 {
    if (max_iter == iter) {
        return slice.len;
    }

    var sum: u64 = 0;
    var res: u64 = 0;
    for (slice) |item| {
        if (memo.get(.{ iter, item })) |val| {
            sum += val;
            continue;
        }
        if (item == 0) {
            res = recIter(alloc, max_iter, iter + 1, &.{1}, memo);
        } else {
            const digits = std.math.log10_int(item);
            if (@mod(digits, 2) == 1) { // Add 1 digit later, "optimization"
                const pow = std.math.powi(u64, 10, @divExact(digits + 1, 2)) catch unreachable;
                res = recIter(alloc, max_iter, iter + 1, &.{ @divFloor(item, pow), @mod(item, pow) }, memo);
            } else {
                res = recIter(alloc, max_iter, iter + 1, &.{item * 2024}, memo);
            }
        }
        sum += res;
        memo.*.put(.{ iter, item }, res) catch unreachable;
    }
    return sum;
}
