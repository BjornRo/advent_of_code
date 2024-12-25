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
const GraphValue = std.ArrayList(u16);
const Graph = std.AutoHashMap(u16, GraphValue);

fn stringToInt(str: String) u16 {
    const value: u16 = @bitCast([2]u8{ str[0], str[1] });
    return if (.big == endian) value else @byteSwap(value);
}

fn intToString(int: u16) [2]u8 {
    const value = if (.big == endian) int else @byteSwap(int);
    return @bitCast(value);
}

fn matchChar(value: u48) bool {
    var res = value;
    for (0..4) |_| {
        if ((res & 0xFF) == 't') {
            return true;
        }
        res >>= 16;
    }
    return false;
}

fn intToInt(key: [3]u16) u48 {
    const value: u48 = @bitCast(key);
    return if (.big == endian) value else @byteSwap(value);
}

fn part1(allocator: Allocator, graph: Graph) !u16 {
    var set = std.AutoHashMap(u48, void).init(allocator);
    try set.ensureTotalCapacity(graph.count() * graph.count());
    defer set.deinit();

    var sum: u16 = 0;

    var git = graph.iterator();
    while (git.next()) |item| {
        const neighbors = item.value_ptr.*.items;
        for (neighbors) |n0| {
            for (neighbors[1..]) |n1| {
                if (!isConnected(graph, n0, n1)) continue;
                var group: [3]u16 = .{ item.key_ptr.*, n0, n1 };
                // printa(group);

                std.mem.sort(u16, &group, {}, std.sort.asc(u16));
                const x = intToInt(group);
                // printa(x);

                if (set.getOrPutAssumeCapacity(x).found_existing) continue;
                if (matchChar(x)) {
                    sum += 1;
                    break;
                }
            }
        }
    }
    return sum;
}

fn isConnected(graph: Graph, node0: u16, node1: u16) bool {
    if (graph.get(node0)) |neighbors| {
        for (neighbors.items) |neighbor| {
            if (neighbor == node1) return true;
        }
    }
    return false;
}

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
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

    var graph = Graph.init(allocator);
    defer {
        var git = graph.valueIterator();
        while (git.next()) |v| v.deinit();
        graph.deinit();
    }

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        const split = std.mem.indexOfScalar(u8, row, '-').?;
        const node0 = stringToInt(row[0..split]);
        const node1 = stringToInt(row[split + 1 ..]);
        var res = try graph.getOrPut(node0);
        if (!res.found_existing) res.value_ptr.* = try GraphValue.initCapacity(allocator, 15);
        res.value_ptr.*.appendAssumeCapacity(node1);
        // Undirected
        res = try graph.getOrPut(node1);
        if (!res.found_existing) res.value_ptr.* = try GraphValue.initCapacity(allocator, 15);
        res.value_ptr.*.appendAssumeCapacity(node0);
    }

    const p2 = try part2(allocator, graph);
    defer allocator.free(p2);

    try writer.print("Part 1: {d}\nPart 2: {s}\n", .{ try part1(allocator, graph), p2 });
}

fn part2(allocator: Allocator, graph: Graph) !String {
    var map = std.AutoHashMap(u16, void).init(allocator);
    try map.ensureTotalCapacity(15); // tested max len: 13
    defer map.deinit();

    var conn_list = std.ArrayList(u16).init(allocator);
    defer conn_list.deinit();

    var max_conn: u8 = 0;

    var git = graph.iterator();
    while (git.next()) |item| {
        map.clearRetainingCapacity();
        map.putAssumeCapacity(item.key_ptr.*, {});

        var conn: u8 = 0;
        const neighbors = item.value_ptr.*.items;
        outer: for (neighbors) |n0| {
            for (neighbors[1..]) |n1| {
                if (!isConnected(graph, n0, n1)) continue :outer;
                map.putAssumeCapacity(n0, {});
                map.putAssumeCapacity(n1, {});
                conn += 1;
            }
        }
        if (conn <= max_conn) continue;
        conn_list.clearRetainingCapacity();
        max_conn = conn;
        var m_it = map.keyIterator();
        while (m_it.next()) |node| try conn_list.append(node.*);
    }

    std.mem.sort(u16, conn_list.items, {}, std.sort.asc(u16));
    var list = try std.ArrayList(String).initCapacity(allocator, conn_list.items.len);
    defer list.deinit();
    for (conn_list.items) |item| {
        list.appendAssumeCapacity(&intToString(item));
    }
    return try myf.joinStrings(allocator, list.items, ",");
}
