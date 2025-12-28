const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const CT = u8;
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
            .ore_bot = num_iter.next().?,
            .clay_bot = num_iter.next().?,
            .obsidian_bot = .{ .ore = num_iter.next().?, .clay = num_iter.next().? },
            .geode_bot = .{ .ore = num_iter.next().?, .obsidian = num_iter.next().? },
        });
    }

    // var total: usize = 0;
    // for (blueprints.items, 1..) |blueprint, i| {
    //     total += i * try oreStatemachine(alloc, blueprint);
    // }

    var list: std.ArrayList(usize) = .empty;
    defer list.deinit(alloc);

    for (blueprints.items) |blueprint| {
        try list.append(alloc, try oreStatemachine(alloc, blueprint));
    }

    // std.mem.sortUnstable(usize, list.items, {}, std.sort.desc(usize));

    std.debug.print("{any}\n", .{list.items});

    return .{ .p1 = 1, .p2 = 2 };
}

fn oreStatemachine(alloc: Allocator, blueprint: BlueprintCosts) !usize {
    const State = struct {
        ore_bot: u8,
        clay_bot: u8,
        obsidian_bot: u8,
        geode_bot: u8,
        ore: u8,
        clay: u8,
        obsidian: u8,
        geode: u8,
        const Self = @This();
        fn unpack(self: Self) [8]u8 {
            return .{ self.ore_bot, self.clay_bot, self.obsidian_bot, self.geode_bot, self.ore, self.clay, self.obsidian, self.geode };
        }
    };
    var states: std.ArrayList(State) = .empty;
    var next_states: std.ArrayList(State) = .empty;
    defer states.deinit(alloc);
    defer next_states.deinit(alloc);
    var visited: std.AutoHashMap(State, void) = .init(alloc);
    defer visited.deinit();

    try states.append(alloc, .{
        .ore_bot = 1,
        .clay_bot = 0,
        .obsidian_bot = 0,
        .geode_bot = 0,
        .ore = 0,
        .clay = 0,
        .obsidian = 0,
        .geode = 0,
    });
    var max_geodes: u16 = 0;
    for (0..32) |k| {
        defer {
            const tmp = states;
            std.debug.print("{d}: {d},{d}\n", .{ k, states.items.len, next_states.items.len });
            states = next_states;
            next_states = tmp;
            next_states.clearRetainingCapacity();
        }
        for (states.items) |state| {
            const ore_bot, const clay_bot, const obsidian_bot, const geode_bot, const ore, const clay, const obsidian, const geode = state.unpack();
            if (k > 12 and geode < max_geodes) continue;
            max_geodes = @max(max_geodes, geode);

            const res = try visited.getOrPut(state);
            if (res.found_existing) continue;

            // ore += ore_bot;
            // clay += clay_bot;
            // obsidian += obsidian_bot;
            // geode += geode_bot;

            try next_states.append(alloc, .{
                .ore_bot = ore_bot,
                .clay_bot = clay_bot,
                .obsidian_bot = obsidian_bot,
                .geode_bot = geode_bot,
                .ore = ore + ore_bot,
                .clay = clay + clay_bot,
                .obsidian = obsidian + obsidian_bot,
                .geode = geode + geode_bot,
            });
            // Ore bot
            if (ore >= blueprint.ore_bot) try next_states.append(alloc, .{
                .ore_bot = ore_bot + 1,
                .clay_bot = clay_bot,
                .obsidian_bot = obsidian_bot,
                .geode_bot = geode_bot,
                .ore = ore - blueprint.ore_bot + ore_bot,
                .clay = clay + clay_bot,
                .obsidian = obsidian + obsidian_bot,
                .geode = geode + geode_bot,
            });
            // Clay bot
            if (ore >= blueprint.clay_bot) try next_states.append(alloc, .{
                .ore_bot = ore_bot,
                .clay_bot = clay_bot + 1,
                .obsidian_bot = obsidian_bot,
                .geode_bot = geode_bot,
                .ore = ore - blueprint.clay_bot + ore_bot,
                .clay = clay + clay_bot,
                .obsidian = obsidian + obsidian_bot,
                .geode = geode + geode_bot,
            });
            // Obsidian bot
            if (ore >= blueprint.obsidian_bot.ore and clay >= blueprint.obsidian_bot.clay) try next_states.append(alloc, .{
                .ore_bot = ore_bot,
                .clay_bot = clay_bot,
                .obsidian_bot = obsidian_bot + 1,
                .geode_bot = geode_bot,
                .ore = ore - blueprint.obsidian_bot.ore + ore_bot,
                .clay = clay - blueprint.obsidian_bot.clay + clay_bot,
                .obsidian = obsidian + obsidian_bot,
                .geode = geode + geode_bot,
            });
            // Geode bot
            if (ore >= blueprint.geode_bot.ore and obsidian >= blueprint.geode_bot.obsidian) try next_states.append(alloc, .{
                .ore_bot = ore_bot,
                .clay_bot = clay_bot,
                .obsidian_bot = obsidian_bot,
                .geode_bot = geode_bot + 1,
                .ore = ore - blueprint.geode_bot.ore + ore_bot,
                .clay = clay + clay_bot,
                .obsidian = obsidian - blueprint.geode_bot.obsidian + obsidian_bot,
                .geode = geode + geode_bot,
            });
        }
    }
    var max_geode: u16 = 0;
    for (states.items) |state| {
        max_geode = @max(max_geode, state.geode);
        // std.debug.print("{d}\n", .{state.geode});
    }
    return max_geode;
}
