const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const CT = u8;
const Vec4 = @Vector(4, CT);
const BlueprintCosts = struct { ore_bot: Vec4, clay_bot: Vec4, obsidian_bot: Vec4, geode_bot: Vec4 };
const State = packed struct { bots: Vec4, minerals: Vec4 };
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const alloc, const is_debug = switch (@import("builtin").mode) {
        .Debug => .{ debug_allocator.allocator(), true },
        else => .{ std.heap.smp_allocator, false },
    };
    const start = std.time.microTimestamp();
    defer {
        std.debug.print("Time: {any}s\n", .{@as(f64, @floatFromInt(std.time.microTimestamp() - start)) / 1000_000});
        if (is_debug) _ = debug_allocator.deinit();
    }

    const data = try utils.read(alloc, "in/d19.txt");
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
        var num_iter = utils.NumberIter(CT).init(item[std.mem.indexOfScalar(u8, item, ':').? + 10 ..]);
        try blueprints.append(alloc, .{
            .ore_bot = .{ num_iter.next().?, 0, 0, 0 },
            .clay_bot = .{ num_iter.next().?, 0, 0, 0 },
            .obsidian_bot = .{ num_iter.next().?, num_iter.next().?, 0, 0 },
            .geode_bot = .{ 0, num_iter.next().?, num_iter.next().?, 0 },
        });
    }

    var total_1: usize = 0;
    for (blueprints.items, 1..) |blueprint, i| total_1 += i * try oreStatemachine(alloc, blueprint, 24);
    var total_2: usize = 1;
    for (blueprints.items[0..3]) |blueprint| total_2 *= try oreStatemachine(alloc, blueprint, 32);
    return .{ .p1 = total_1, .p2 = total_2 };
}
fn oreStatemachine(alloc: Allocator, blueprint: BlueprintCosts, generations: usize) !usize {
    var states: std.ArrayList(State) = .empty;
    var next: @TypeOf(states) = .empty;
    var visited: std.HashMap(State, void, utils.HashIntCtx(State), 90) = .init(alloc);
    defer states.deinit(alloc);
    defer next.deinit(alloc);
    defer visited.deinit();

    try states.append(alloc, .{ .bots = .{ 1, 0, 0, 0 }, .minerals = @splat(0) });
    var max_geode: u8 = 0;
    for (0..generations) |_| {
        defer {
            std.mem.swap(@TypeOf(states), &states, &next);
            next.clearRetainingCapacity();
        }
        for (states.items) |st| {
            const ore, const clay, const obsidian, const geode = st.minerals;
            if (geode < max_geode or (try visited.getOrPut(st)).found_existing) continue;
            max_geode = @max(max_geode, geode);

            const new_res = st.bots + st.minerals;
            if (ore >= blueprint.geode_bot[0] and obsidian >= blueprint.geode_bot[2]) {
                try next.append(alloc, .{ .bots = st.bots + Vec4{ 0, 0, 0, 1 }, .minerals = new_res - blueprint.geode_bot });
                continue;
            }
            if (ore >= blueprint.obsidian_bot[0] and clay >= blueprint.obsidian_bot[1]) {
                try next.append(alloc, .{ .bots = st.bots + Vec4{ 0, 0, 1, 0 }, .minerals = new_res - blueprint.obsidian_bot });
                continue;
            }
            if (ore >= blueprint.ore_bot[0])
                try next.append(alloc, .{ .bots = st.bots + Vec4{ 1, 0, 0, 0 }, .minerals = new_res - blueprint.ore_bot });
            if (ore >= blueprint.clay_bot[0])
                try next.append(alloc, .{ .bots = st.bots + Vec4{ 0, 1, 0, 0 }, .minerals = new_res - blueprint.clay_bot });
            try next.append(alloc, .{ .bots = st.bots, .minerals = new_res });
        }
    }
    max_geode = 0;
    for (states.items) |state| max_geode = @max(max_geode, state.minerals[3]);
    return max_geode;
}
