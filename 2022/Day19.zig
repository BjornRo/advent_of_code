const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const CT = u8;
const Vec4 = @Vector(4, CT);
const BlueprintCosts = struct { ore_bot: Vec4, clay_bot: Vec4, obsidian_bot: Vec4, geode_bot: Vec4 };
const State = packed struct {
    bots: Vec4,
    resources: Vec4,
    const Self = @This();
    const HashCtx = struct {
        pub fn hash(_: @This(), key: State) u64 {
            return utils.hashU64(@bitCast(key));
        }
        pub fn eql(_: @This(), a: State, b: State) bool {
            const _a: u64 = @bitCast(a);
            const _b: u64 = @bitCast(b);
            return _a == _b;
        }
    };
};
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

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
        const index = std.mem.indexOfScalar(u8, item, ':').?;
        var num_iter = utils.NumberIter(CT).init(item[index..]);
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
    var next_states: std.ArrayList(State) = .empty;
    defer states.deinit(alloc);
    defer next_states.deinit(alloc);
    var visited: std.HashMap(State, void, State.HashCtx, 90) = .init(alloc);
    defer visited.deinit();

    try states.append(alloc, .{ .bots = .{ 1, 0, 0, 0 }, .resources = .{ 0, 0, 0, 0 } });
    var max_geodes: u16 = 0;
    for (0..generations) |_| {
        defer {
            const tmp = states;
            states = next_states;
            next_states = tmp;
            next_states.clearRetainingCapacity();
        }
        for (states.items) |state| {
            const ore, const clay, const obsidian, const geode = state.resources;
            if (geode < max_geodes) continue;
            const res = try visited.getOrPut(state);
            if (res.found_existing) continue;
            max_geodes = @max(max_geodes, geode);

            try next_states.append(alloc, .{ .bots = state.bots, .resources = state.bots + state.resources });
            if (ore >= blueprint.ore_bot[0]) try next_states.append(alloc, .{
                .bots = state.bots + Vec4{ 1, 0, 0, 0 },
                .resources = state.resources + state.bots - blueprint.ore_bot,
            });
            if (ore >= blueprint.clay_bot[0]) try next_states.append(alloc, .{
                .bots = state.bots + Vec4{ 0, 1, 0, 0 },
                .resources = state.resources + state.bots - blueprint.clay_bot,
            });
            if (ore >= blueprint.obsidian_bot[0] and clay >= blueprint.obsidian_bot[1]) try next_states.append(alloc, .{
                .bots = state.bots + Vec4{ 0, 0, 1, 0 },
                .resources = state.resources + state.bots - blueprint.obsidian_bot,
            });
            if (ore >= blueprint.geode_bot[0] and obsidian >= blueprint.geode_bot[2]) try next_states.append(alloc, .{
                .bots = state.bots + Vec4{ 0, 0, 0, 1 },
                .resources = state.resources + state.bots - blueprint.geode_bot,
            });
        }
    }
    var max_geode: u16 = 0;
    for (states.items) |state| max_geode = @max(max_geode, state.resources[3]);
    return max_geode;
}
