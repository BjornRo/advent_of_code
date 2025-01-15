const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const Graph = std.HashMap(u24, u24, HashCtx, 80);

const HashCtx = struct {
    pub fn hash(_: @This(), key: u24) u64 {
        return @intCast(std.hash.uint32(@intCast(key)));
    }
    pub fn eql(_: @This(), a: u24, b: u24) bool {
        return a == b;
    }
};

fn intArrToInt(key: []const u8) u24 {
    const b0: u24 = @intCast(key[0]);
    const b1: u24 = @intCast(key[1]);
    const b2: u24 = @intCast(key[2]);
    return (b0 << 16) | (b1 << 8) | b2;
}

fn part1(graph: *Graph) usize {
    var sum: usize = 0;
    var key_it = graph.keyIterator();

    while (key_it.next()) |key| {
        var curr = key.*;
        while (graph.get(curr)) |next| {
            curr = next;
            sum += 1;
        }
    }
    return sum;
}

fn part2(allocator: Allocator, graph: *Graph) !usize {
    var visited = Graph.init(allocator);
    defer visited.deinit();
    try visited.ensureTotalCapacity(graph.count());

    for ([2]u24{ intArrToInt("YOU"), intArrToInt("SAN") }) |key| {
        var sum: u24 = 0;
        var curr = key;
        while (graph.get(curr)) |next| {
            const result = visited.getOrPutAssumeCapacity(curr);
            if (result.found_existing) return @intCast(sum + result.value_ptr.* - 2);
            result.value_ptr.* = sum;
            curr = next;
            sum += 1;
        }
    }
    unreachable;
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [70_000]u8 = undefined;
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
        const node0 = intArrToInt(row[0..3]);
        const node1 = intArrToInt(row[4..7]);
        const res = try graph.getOrPut(node1);
        if (!res.found_existing) res.value_ptr.* = node0;
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ part1(&graph), try part2(allocator, &graph) });
}
