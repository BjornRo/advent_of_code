const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    // const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    // std.debug.print("{s}\n", .{input});
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

const MoveType = union(enum) {
    deal_with_inc: i64,
    cut: i64,
    deal_into,
};

// too high 75756230842694, 38515460445925
test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d22.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var procedure_list = std.ArrayList(MoveType).init(allocator);
    defer procedure_list.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        if (std.mem.startsWith(u8, row, "deal int")) {
            try procedure_list.append(.deal_into);
            continue;
        }
        const value = try std.fmt.parseInt(i64, row[std.mem.lastIndexOfScalar(u8, row, ' ').? + 1 ..], 10);

        const move: MoveType = if (row[0] == 'd') .{ .deal_with_inc = value } else .{ .cut = value };
        try procedure_list.append(move);
    }

    var buf: [10007]i128 = undefined;
    for (0..10007) |i| buf[@intCast(try part1(&procedure_list.items, 10007, 3, i))] = i;
    std.debug.print("{any}, exp: {d}\n\n", .{ buf[2019..2022], buf[2020] });
    // 2020(3 shuffles): 7033

    // print(try part1(&procedure_list.items, 10007, 0));
    try part2(&procedure_list.items, 10007, 3, 2020);
    // try part2(&procedure_list.items, 119315717514047, 101741582076661, 2020);
}

fn part2(procedures: *const []const MoveType, len: i128, shuffles: i128, card_index: usize) !void {
    var index: i128 = 0;

    for (procedures.*) |proc| {
        switch (proc) {
            .deal_into => {
                index = len - 1 - index;
            },
            .cut => |value| {
                index = @mod(index - value, len);
            },
            .deal_with_inc => |value| {
                // std.debug.print("{d} {d}\n\n", .{ value, value_ });
                index = @mod(index * try myf.modInv(value, len), len);
            },
        }
    }

    _ = card_index;
    _ = shuffles;

    // 19
    // 119315717514047

    // const xx = @mod(card_index * inc, len) - 1;
    // print(xx);

    // print(offset);
}

fn part1(procedures: *const []const MoveType, len: i128, n_shuffles: usize, card_index: usize) !i128 {
    var index: i128 = @intCast(card_index);
    for (0..n_shuffles) |_| {
        for (procedures.*) |proc| {
            index = switch (proc) {
                .deal_into => @mod(len - 1 - index, len),
                .cut => |value| @mod(index - value, len),
                .deal_with_inc => |value| @mod(index * value, len),
            };
        }
    }
    return index;
}
