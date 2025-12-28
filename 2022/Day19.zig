const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const CT = i32;
const Ore = CT;
const Clay = CT;
const Obsidian = CT;
const BlueprintCosts = struct {
    ore_bot: Ore,
    clay_bot: Ore,
    obsidian_bot: struct { ore: Ore, clay: Clay },
    geode_bot: struct { ore: Ore, obsidian: Obsidian },
};
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d19t.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var blueprints: std.ArrayList(BlueprintCosts) = .empty;
    defer blueprints.deinit(alloc);

    var split_iter = std.mem.splitScalar(u8, data, '\n');
    while (split_iter.next()) |item| {
        const index = std.mem.indexOfScalar(u8, item, ':').?;
        var num_iter = utils.NumberIter(u8).init(item[index..]);
        try blueprints.append(alloc, .{
            .ore_bot = num_iter.next().?,
            .clay_bot = num_iter.next().?,
            .obsidian_bot = .{ .ore = num_iter.next().?, .clay = num_iter.next().? },
            .geode_bot = .{ .ore = num_iter.next().?, .obsidian = num_iter.next().? },
        });
    }

    return .{ .p1 = 1, .p2 = 2 };
}
