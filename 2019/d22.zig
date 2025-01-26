const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const MoveType = union(enum) {
    deal_with_inc: i64,
    cut: i64,
    deal_into,
};

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

fn part2(
    allocator: Allocator,
    procedures: *const []const MoveType,
    len: i128,
    shuffles: i128,
    card_index: usize,
) !u64 {
    var prods_fac: i128 = 1;
    var adds_fac: i128 = 0;

    var rev_it = std.mem.reverseIterator(procedures.*);
    while (rev_it.next()) |proc| {
        switch (proc) {
            .deal_into => adds_fac = len - 1 - adds_fac,
            .cut => |value| adds_fac = @mod(adds_fac + value, len),
            .deal_with_inc => |value| {
                const inv = try myf.modInv(value, len);
                prods_fac = @mod(prods_fac * inv, len);
                adds_fac = @mod(adds_fac * inv, len);
            },
        }
    }

    const python_code =
        "muls={d};adds={d};index={d};shuffles={d};len={d};\n" ++
        "mul_pow = pow(muls, shuffles, len)\n" ++
        "adds = (adds * (1 - mul_pow) * pow(1 - muls, -1, len)) % len\n" ++
        "print((mul_pow * index + adds) % len, end='')";

    const str = try std.fmt.allocPrint(allocator, python_code, .{ prods_fac, adds_fac, card_index, shuffles, len });
    defer allocator.free(str);

    var child = std.process.Child.init(&[_][]const u8{ "python", "-c", str }, allocator);
    child.stdout_behavior = .Pipe;
    try child.spawn();

    const result = try child.stdout.?.reader().readAllAlloc(allocator, 20);
    defer allocator.free(result);

    _ = try child.wait();
    return std.fmt.parseInt(u64, result, 10);
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

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

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        try part1(&procedure_list.items, 10007, 1, 2019),
        try part2(allocator, &procedure_list.items, 119315717514047, 101741582076661, 2020),
    });
}
