const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const print = myf.printAny;
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
    // const input = @embedFile("in/d11.txt");
    // End setup

    const input = "337 42493\r\n";
    const input_attributes = try myf.getInputAttributes(input);

    var list = try std.ArrayList(u64).initCapacity(
        allocator,
        @intCast(1 + std.mem.count(u8, input[0..input_attributes.row_len], " ")),
    );
    defer list.deinit();

    var in_iter = std.mem.splitScalar(u8, input[0..input_attributes.row_len], ' ');
    while (in_iter.next()) |elem| {
        list.appendAssumeCapacity(try std.fmt.parseInt(u64, elem, 10));
        // try deque.pushBack(try std.fmt.parseInt(u64, elem, 10));
    }

    // var deque = try Deque(u64).init(allocator);
    // defer deque.deinit();
    // 233875
    var sum: u64 = 0;
    var list2 = std.ArrayList(u64).init(allocator);
    defer list2.deinit();
    for (list.items) |elem| {
        var deque = try Deque(u64).init(allocator);
        defer deque.deinit();

        try deque.pushBack(elem);
        var prev_len = deque.len();
        for (0..25) |_| {
            defer list2.clearRetainingCapacity();
            for (0..deque.len()) |_| {
                const item = deque.popFront().?;
                if (item == 0) {
                    try list2.append(1);
                    try deque.pushBack(1);
                    continue;
                }
                const digits = std.math.log10_int(item);
                if (@mod(digits, 2) == 1) { // Add 1 digit later, "optimization"
                    const pow = try std.math.powi(u64, 10, @divExact(digits + 1, 2));
                    inline for (.{ @divFloor(item, pow), @mod(item, pow) }) |new_item| {
                        try deque.pushBack(new_item);
                        try list2.append(new_item);
                    }
                    continue;
                }
                try list2.append(item * 2024);
                try deque.pushBack(item * 2024);
            }
            const new_len = deque.len();
            // std.debug.print("{d} = prev: {d} | new: {d} | m: {d}\n", .{ i + 1, prev_len, new_len, myf.lcm(prev_len, new_len) });
            // std.debug.print("{d} = prev: {d} | new: {d} | m: {d}\n", .{ i + 1, prev_len, new_len, std.math.gcd(prev_len, new_len) });
            // std.debug.print("{d} = prev: {d} | new: {d} | m: {d}\n", .{ i + 1, prev_len, new_len, new_len - prev_len });
            // print(list2.items);

            // std.debug.print("{d} = {d}\n", .{ i + 1, list2.items.len });
            // print(list2.items);
            // std.debug.print("\n", .{});

            prev_len = new_len;
        }
        sum += deque.len();
    }
    print(sum);
    // 0 -> 4 cycles until 0 -> 4 items
    // 1 -> 4 cycles until 1 -> 4 items
    // 2 -> 7 cycles until 2 -> 16 items
    // 3 -> 8 cycles until 3 -> 26 items
    // 4 -> 7 cycles until 4 -> 16 items
    // 5 -> no cycles
    // 6 -> 5 cycles until 6 -> 8 items
    // 7 -> 5 cycles until 7 -> 8 items
    // 8 -> 4 cycles until 8 -> 4 items
    // 9 -> 5 cycles until 9 -> 8 items

    // 0 -> 5 iter -> 2 0 2 4
    // 1 -> 3 iter -> 2 0 2 4
    // 2 -> 3 iter -> 4 0 4 8
    // 3 -> 3 iter -> 6 0 7 2
    // 4 -> 3 iter -> 8 0 9 6
    // 5 -> 5 iter -> 2 0 4 8 2 8 8 0
    // 6 -> 5 iter -> 2 4 5 7 9 4 5 6
    // 7 -> 5 iter -> 2 8 6 7 6 0 3 2
    // 8 -> 5 iter -> 3 2 7 7 2 6 16192, 6 iter -> 6072, 4048, 14168, 14168, 4048, 12144, 32772608, cycle 1-6 32772608
    // 9 -> 5 iter -> 3 6 8 6 9 1 8 4
    // print(sum);
    // 32772608 -> 4 iter -> 7 items with ending 32772608
    // 8 -> 4 iter = 4 items -> 8 iter = 22 items
    // { 16192 }
    // { 32772608 }
    // { 3277, 2608 }
    // { 32, 77, 26, 8 }
    // { 3, 2, 7, 7, 2, 6, 16192 } -> iter 5
    // 3 -> 8 ending 6 iter
    //

}
