const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

// const GraphValue = std.ArrayList(u24);
const Graph = std.HashMap(u24, u24, HashCtx, 90);

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

fn intToString(int: u24) [3]u8 {
    return .{ @truncate(int >> 16), @truncate(int >> 8), @truncate(int) };
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    // const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    // std.debug.print("{s}\n", .{input});
    // std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d06.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var graph = Graph.init(allocator);
    defer {
        // var gvit = graph.valueIterator();
        // while (gvit.next()) |v| v.deinit();
        graph.deinit();
    }

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        const node0 = intArrToInt(row[0..3]);
        const node1 = intArrToInt(row[4..7]);
        const res = try graph.getOrPut(node1);
        if (!res.found_existing) res.value_ptr.* = node0;
        // try res.value_ptr.*.append(node0);
    }
    _ = part1(&graph);
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
    //
    print(sum);
    return 1;
}
