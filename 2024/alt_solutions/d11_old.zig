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
    const input = @embedFile("in/d11.txt");
    // End setup

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

    var sum: u64 = 0;
    for (list.items) |elem| {
        var deque = try Deque(u64).init(allocator);
        defer deque.deinit();

        try deque.pushBack(elem);
        for (0..25) |_| {
            for (0..deque.len()) |_| {
                const item = deque.popFront().?;
                if (item == 0) {
                    try deque.pushBack(1);
                    continue;
                }
                const digits = std.math.log10_int(item);
                if (@mod(digits, 2) == 1) { // Add 1 digit later, "optimization"
                    const pow = try std.math.powi(u64, 10, @divExact(digits + 1, 2));
                    inline for (.{ @divFloor(item, pow), @mod(item, pow) }) |new_item| {
                        try deque.pushBack(new_item);
                    }
                    continue;
                }
                try deque.pushBack(item * 2024);
            }
        }
        sum += deque.len();
    }
    print(sum);
}
