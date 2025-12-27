const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d10t.txt");
    defer alloc.free(data);

    part1(alloc, data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(_: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var split_iter = std.mem.splitScalar(u8, data, '\n');
    while (split_iter.next()) |_| {
        //
    }

    return .{ .p1 = 1, .p2 = 2 };
}
const rocks: [5][]const []const u8 = .{
    &.{"####"},
    &.{
        ".#.",
        "###",
        ".#.",
    },
    &.{
        "..#",
        "..#",
        "###",
    },
    &.{
        "#",
        "#",
        "#",
        "#",
    },
    &.{
        "##",
        "##",
    },
};

fn part1(alloc: Allocator, data: []const u8) void {
    _ = alloc;

    var rocks_iter = utils.Repeat([]const []const u8).init(&rocks);
    var input_iter = utils.Repeat(u8).init(data);

    for (0..5) |_| {
        std.debug.print("{any},{d}\n", .{ rocks_iter.next(), input_iter.next() });
    }

    //
}
