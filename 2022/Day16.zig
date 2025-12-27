const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const Memo = std.AutoHashMap(struct { u8, u64, u8 }, u32);
const Memo2 = std.AutoHashMap(struct { u8, u8, u64, u8 }, u32);
const BitSet = std.bit_set.IntegerBitSet(64);
const GraphValue = struct { flow: u32, valves: BitSet };
const Graph = std.AutoHashMap(u8, GraphValue);

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d16t.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var mapper: std.AutoHashMap([2]u8, u8) = .init(alloc);
    var graph: Graph = .init(alloc);
    defer mapper.deinit();
    defer graph.deinit();
    {
        var parsing_step: std.ArrayList(struct { key: [2]u8, flow: u32, neighbors: []const u8 }) = .empty;
        defer parsing_step.deinit(alloc);

        var k: u8 = 0;
        var split_iter = std.mem.splitScalar(u8, data, '\n');
        while (split_iter.next()) |*item| : (k += 1) {
            const flow = utils.firstNumber(u32, 10, item.*).?.value;
            const index = if (std.mem.lastIndexOf(u8, item.*, "valve ")) |i|
                i + 6
            else
                std.mem.lastIndexOf(u8, item.*, "valves ").? + 7;

            const key = item.*[6..8][0..2].*;
            try parsing_step.append(alloc, .{ .key = key, .flow = flow, .neighbors = item.*[index..] });
            try mapper.put(key, k);
        }

        for (parsing_step.items) |item| {
            var neighbors: BitSet = .initEmpty();
            var iter = std.mem.splitSequence(u8, item.neighbors, ", ");
            while (iter.next()) |*n| neighbors.set(mapper.get(n.*[0..2].*).?);
            try graph.put(mapper.get(item.key).?, .{ .flow = item.flow, .valves = neighbors });
        }
    }

    var memo = Memo.init(alloc);
    defer memo.deinit();
    return .{
        .p1 = try valver(&graph, mapper.get(.{ 'A', 'A' }).?, 30, .initEmpty(), &memo),
        .p2 = try valver2(alloc, &graph, mapper.get(.{ 'A', 'A' }).?),
    };
}
fn valver(graph: *Graph, node: u8, minutes: u8, valves: BitSet, memo: *Memo) !u32 {
    if (minutes <= 0) return 0;
    if (memo.get(.{ node, valves.mask, minutes })) |val| return val;

    var max_pressure: u32 = 0;
    const value = graph.get(node).?;
    if (value.flow > 0 and !valves.isSet(node)) {
        var new_bitset = valves;
        new_bitset.set(node);
        max_pressure = @max(max_pressure, try valver(graph, node, minutes - 1, new_bitset, memo));
    }
    var neighbors_iter = value.valves.iterator(.{});
    while (neighbors_iter.next()) |next_valve| {
        max_pressure = @max(max_pressure, try valver(graph, @intCast(next_valve), minutes - 1, valves, memo));
    }

    var valve_iter = valves.iterator(.{});
    while (valve_iter.next()) |i| max_pressure += graph.get(@intCast(i)).?.flow;
    try memo.put(.{ node, valves.mask, minutes }, max_pressure);
    return max_pressure;
}
fn pack(a: u8, b: u8, c: u16) u64 {
    return (@as(u64, @intCast(a)) << 20) | (@as(u64, @intCast(b)) << 14) | c;
}
const Key = struct { u8, u8, u64 };
// const HashCtx = struct {
//     pub fn hash(_: @This(), key: Key) u64 {
//         return utils.hashU64((@as(u64, @intCast(key.@"0")) << 58) | (@as(u64, @intCast(key.@"1")) << 52) | key.@"2");
//     }
//     pub fn eql(_: @This(), a: Key, b: Key) bool {
//         return a.@"0" == b.@"0" and a.@"1" == b.@"1" and a.@"2" == b.@"2";
//     }
// };
fn valver2(alloc: Allocator, graph: *Graph, node1: u8) !u32 {
    const State = struct { u8, u8, BitSet, u32 };
    const VisitKey = struct { u8, u8, u64 };
    var visited: std.AutoHashMap(VisitKey, u32) = .init(alloc);
    var states: std.ArrayList(State) = .empty;
    var next_states: std.ArrayList(State) = .empty;
    defer visited.deinit();
    defer states.deinit(alloc);
    defer next_states.deinit(alloc);

    var best_pressure: u32 = 0;
    try states.append(alloc, .{ node1, node1, .initEmpty(), 0 });
    for (0..26) |_| {
        defer {
            const tmp = states;
            states = next_states;
            next_states = tmp;
            next_states.clearRetainingCapacity();
        }
        for (states.items) |state| {
            const n1, const n2, const open_valves, const pressure = state;
            // {
            //     const vkey: VisitKey = .{ n1, n2, open_valves.mask };
            //     const res = try visited.getOrPut(vkey);
            //     if (res.found_existing) {
            //         if (res.value_ptr.* >= pressure) continue;
            //         res.value_ptr.* = pressure;
            //     } else res.key_ptr.* = vkey;
            // }
            var new_pressure: u32 = pressure;

            var valve_iter = open_valves.iterator(.{});
            while (valve_iter.next()) |i| new_pressure += graph.get(@intCast(i)).?.flow;
            // var potential = new_pressure;
            // var giter = graph.iterator();
            // while (giter.next()) |kv| {
            //     if (!open_valves.isSet(kv.key_ptr.*) and kv.value_ptr.flow > 0)
            //         potential += kv.value_ptr.flow;
            // }
            // if (potential <= best_pressure) continue;

            const n1_valve = graph.get(n1).?;
            const n2_valve = graph.get(n2).?;
            if (n1_valve.flow > 0 and !open_valves.isSet(n1) and n2_valve.flow > 0 and !open_valves.isSet(n2)) {
                var new_bitset = open_valves;
                new_bitset.set(n1);
                new_bitset.set(n2);
                best_pressure = @max(best_pressure, new_pressure + n1_valve.flow + n2_valve.flow);
                try next_states.append(alloc, .{ n1, n2, new_bitset, new_pressure });
            }
            if (n1_valve.flow > 0 and !open_valves.isSet(n1)) {
                var neighbors_iter = n2_valve.valves.iterator(.{});
                while (neighbors_iter.next()) |next_n2| {
                    var new_bitset = open_valves;
                    new_bitset.set(n1);
                    best_pressure = @max(best_pressure, new_pressure + n1_valve.flow);
                    try next_states.append(alloc, .{ n1, @intCast(next_n2), new_bitset, new_pressure });
                }
            }
            if (n2_valve.flow > 0 and !open_valves.isSet(n2)) {
                var neighbors_iter = n1_valve.valves.iterator(.{});
                while (neighbors_iter.next()) |next_n1| {
                    var new_bitset = open_valves;
                    new_bitset.set(n2);
                    best_pressure = @max(best_pressure, new_pressure + n2_valve.flow);
                    try next_states.append(alloc, .{ @intCast(next_n1), n2, new_bitset, new_pressure });
                }
            }
            var iter1 = n1_valve.valves.iterator(.{});
            while (iter1.next()) |next_n1| {
                var iter2 = n2_valve.valves.iterator(.{});
                while (iter2.next()) |next_n2|
                    try next_states.append(alloc, .{ @intCast(next_n1), @intCast(next_n2), open_valves, new_pressure });
            }
        }
    }
    for (states.items) |value| best_pressure = @max(best_pressure, value.@"3");
    return best_pressure;
}
