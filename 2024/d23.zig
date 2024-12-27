const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;
const endian = @import("builtin").cpu.arch.endian();

const String = []const u8;
const GraphValue = myf.FixedBuffer(u16, 15);
const Graph = std.AutoHashMap(u16, GraphValue);

fn stringToInt(str: String) u16 {
    const b0: u16 = @intCast(str[0]);
    const b1: u16 = @intCast(str[1]);
    return (b0 << 8) | b1;
}

fn intToString(int: u16) [2]u8 {
    return .{ @truncate(int >> 8), @truncate(int) };
}

fn matchChar(value: u48) bool {
    var res = value;
    for (0..3) |_| {
        if ((res & 0xFF00) == 0x7400) return true;
        res >>= 16;
    }
    return false;
}

fn intArrToInt(key: [3]u16) u48 {
    const b0: u48 = @intCast(key[0]);
    const b1: u48 = @intCast(key[1]);
    const b2: u48 = @intCast(key[2]);
    return (b0 << 32) | (b1 << 16) | b2;
}

fn isConnected(graph: Graph, node0: u16, node1: u16) bool {
    var buf = graph.get(node0).?;
    for (buf.getSlice()) |neighbor| if (neighbor == node1) return true;
    return false;
}

fn part1(allocator: Allocator, graph: Graph) !u16 {
    var set = std.AutoHashMap(u48, void).init(allocator);
    try set.ensureTotalCapacity(graph.count() * graph.count());
    defer set.deinit();

    var sum: u16 = 0;

    var git = graph.iterator();
    while (git.next()) |item| {
        const neighbors = item.value_ptr.*.getSlice();
        for (neighbors, 1..) |n0, i| {
            for (neighbors[i..]) |n1| {
                if (!isConnected(graph, n0, n1)) continue;
                var group: [3]u16 = .{ item.key_ptr.*, n0, n1 };
                std.mem.sort(u16, &group, {}, std.sort.desc(u16));
                const key = intArrToInt(group);
                if (set.getOrPutAssumeCapacity(key).found_existing) continue;
                if (matchChar(key)) sum += 1;
            }
        }
    }
    return sum;
}

fn part2(allocator: Allocator, graph: Graph) !String {
    var map = std.AutoHashMap(u16, void).init(allocator);
    try map.ensureTotalCapacity(15); // tested max len: 13
    defer map.deinit();

    var conn_list = myf.FixedBuffer(u16, 15).init();
    var max_conn: u8 = 0;

    var git = graph.iterator();
    while (git.next()) |item| {
        map.clearRetainingCapacity();
        map.putAssumeCapacity(item.key_ptr.*, {});

        var conn: u8 = 0;
        const neighbors = item.value_ptr.*.getSlice();
        outer: for (neighbors, 1..) |n0, i| {
            for (neighbors[i..]) |n1| {
                if (!isConnected(graph, n0, n1)) continue :outer;
                map.putAssumeCapacity(n0, {});
                map.putAssumeCapacity(n1, {});
                conn += 1;
            }
        }
        if (conn <= max_conn) continue;
        conn_list.len = 0;
        max_conn = conn;
        var m_it = map.keyIterator();
        while (m_it.next()) |node| try conn_list.append(node.*);
    }

    std.mem.sort(u16, conn_list.getSlice(), {}, std.sort.asc(u16));
    var list = myf.FixedBuffer([2]u8, 15).init();
    for (conn_list.getSlice()) |item| try list.append(intToString(item));

    return try myf.joinStrings(allocator, list.getSlice(), ",");
}

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [5_000_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    var graph = Graph.init(allocator);
    defer graph.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        const node0 = stringToInt(row[0..2]);
        const node1 = stringToInt(row[3..5]);
        inline for (.{ .{ node0, node1 }, .{ node1, node0 } }) |nodes| {
            const res = try graph.getOrPut(nodes[0]);
            if (!res.found_existing) res.value_ptr.*.len = 0;
            try res.value_ptr.*.append(nodes[1]);
        }
    }

    const p2 = try part2(allocator, graph);
    defer allocator.free(p2);

    try writer.print("Part 1: {d}\nPart 2: {s}\n", .{ try part1(allocator, graph), p2 });
}
