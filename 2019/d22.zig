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

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d22t.txt");
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
    print(procedure_list.items);
    try part1(allocator, &procedure_list.items, 10);
}

fn part1(allocator: Allocator, procedures: *const []const MoveType, len: usize) !void {
    var deck = try allocator.alloc(u32, len);
    defer allocator.free(deck);
    for (deck, 0..) |*d, i| d.* = @intCast(i);
    deck[0] = deck[0];

    for (procedures.*) |proc| {
        switch (proc) {
            .deal_into => std.mem.reverse(u32, deck),
            .cut => |value| {
                _ = value;
            },
            .deal_with_inc => |value| {
                _ = value;
            },
        }
    }
}
