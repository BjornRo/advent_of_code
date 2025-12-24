const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d01.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(allocator: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var calories = std.ArrayList(usize){};
    defer calories.deinit(allocator);

    var splitIter = std.mem.splitScalar(u8, data, '\n');
    var subSum: usize = 0;
    while (splitIter.next()) |item| {
        if (item.len == 0) {
            try calories.append(allocator, subSum);
            subSum = 0;
            continue;
        }
        subSum += try std.fmt.parseUnsigned(usize, item, 10);
    }
    if (subSum != 0) try calories.append(allocator, subSum);

    std.mem.sortUnstable(usize, calories.items, {}, comptime std.sort.desc(usize));
    return .{ .p1 = calories.items[0], .p2 = utils.sum(calories.items[0..3]) };
}
