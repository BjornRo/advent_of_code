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

const HashCtx = struct {
    pub fn hash(_: @This(), key: [3]String) u64 {
        var result: u64 = 0;
        inline for (0..6) |i| {
            const row = i / 2;
            const col = i % 2;
            const char: u64 = @intCast(key[row][col]);
            result |= char << (i * 8);
        }
        return result;
    }

    pub fn eql(_: @This(), a: [3]String, b: [3]String) bool {
        for (a, b) |as, bs| {
            if (!std.mem.eql(u8, as, bs)) return false;
        }
        return true;
    }
};

const String = []const u8;
const GraphValue = std.ArrayList(String);
const Graph = std.StringHashMap(GraphValue);
const String3Set = std.HashMap([3]String, void, HashCtx, 80);

fn part1(allocator: Allocator, graph: Graph) !u16 {
    var set = String3Set.init(allocator);
    try set.ensureTotalCapacity(graph.count() * graph.count());
    defer set.deinit();

    var sum: u16 = 0;

    var git = graph.iterator();
    while (git.next()) |item| {
        const neighbors = item.value_ptr.*.items;
        for (neighbors) |n0| {
            for (neighbors[1..]) |n1| {
                if (!isConnected(graph, n0, n1)) continue;
                var group = nodesToArr3(item.key_ptr.*, n0, n1);
                std.mem.sort(String, &group, {}, sortArr3LessThan);
                if (set.getOrPutAssumeCapacity(group).found_existing) continue;
                for (group) |slice| {
                    if (slice[0] == 't') {
                        sum += 1;
                        break;
                    }
                }
            }
        }
    }
    return sum;
}

fn sortArr3LessThan(_: void, a: String, b: String) bool {
    for (a, b) |ca, ba| {
        if (ca < ba) return true;
        if (ca > ba) return false;
    }
    return false;
}

fn isConnected(graph: Graph, node0: String, node1: String) bool {
    if (graph.get(node0)) |neighbors| {
        for (neighbors.items) |neighbor| {
            if (std.mem.eql(u8, neighbor, node1)) return true;
        }
    }
    return false;
}

fn nodesToArr3(a: String, b: String, c: String) [3]String {
    return .{ a, b, c };
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
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

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
        const node0 = row[0..split];
        const node1 = row[split + 1 ..];
        var res = try graph.getOrPut(node0);
        if (!res.found_existing) res.value_ptr.* = GraphValue.init(allocator);
        try res.value_ptr.*.append(node1);
        // Undirected
        res = try graph.getOrPut(node1);
        if (!res.found_existing) res.value_ptr.* = GraphValue.init(allocator);
        try res.value_ptr.*.append(node0);
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        try part1(allocator, graph),
        0,
    });
}

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d23.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var graph = Graph.init(allocator);
    defer {
        var git = graph.valueIterator();
        while (git.next()) |v| v.deinit();
        graph.deinit();
    }

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        const split = std.mem.indexOfScalar(u8, row, '-').?;
        const node0 = row[0..split];
        const node1 = row[split + 1 ..];
        var res = try graph.getOrPut(node0);
        if (!res.found_existing) res.value_ptr.* = GraphValue.init(allocator);
        try res.value_ptr.*.append(node1);
        // Undirected
        res = try graph.getOrPut(node1);
        if (!res.found_existing) res.value_ptr.* = GraphValue.init(allocator);
        try res.value_ptr.*.append(node0);
    }

    // printa(part1(allocator, graph));
}
