const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const NameValue = struct { value: u64, name: []const u8 };
const Leftovers = std.StringHashMap(u64);
const Map = std.StringHashMap(struct { produces: u64, requires: std.ArrayList(NameValue) });

fn parseElement(raw_elem: []const u8) !NameValue {
    var elem_it = std.mem.tokenizeScalar(u8, raw_elem, ' ');
    const value = try std.fmt.parseInt(u64, elem_it.next().?, 10);
    return .{ .name = elem_it.next().?, .value = value };
}

fn parseLine(allocator: Allocator, line: []const u8, map: *Map) !void {
    var line_it = std.mem.tokenizeSequence(u8, line, " => ");
    const raw_left = line_it.next().?;
    var requires = std.ArrayList(NameValue).init(allocator);
    if (std.mem.indexOfScalar(u8, raw_left, ',') == null) {
        try requires.append(try parseElement(raw_left));
    } else {
        var left_iter = std.mem.tokenizeSequence(u8, raw_left, ", ");
        while (left_iter.next()) |elem| try requires.append(try parseElement(elem));
    }
    const right = try parseElement(line_it.next().?);
    try map.put(right.name, .{ .produces = right.value, .requires = requires });
}

fn oreentating(map: *const Map, symbol: []const u8, requires: u64, leftovers: *Leftovers) !u64 {
    if (map.get(symbol)) |production_map| {
        var ores: u64 = 0;
        const produces = production_map.produces;
        const factor = (requires + produces - 1) / produces;
        (try leftovers.getOrPutValue(symbol, 0)).value_ptr.* += factor * produces - requires;

        for (production_map.requires.items) |req| {
            const adj_req_value = factor * req.value;
            const leftover = try leftovers.getOrPutValue(req.name, 0);
            if (leftover.value_ptr.* >= adj_req_value) {
                leftover.value_ptr.* -= adj_req_value;
            } else {
                const diff_requirement = adj_req_value - leftover.value_ptr.*;
                leftover.value_ptr.* = 0;
                ores += try oreentating(map, req.name, diff_requirement, leftovers);
            }
        }
        return ores;
    }
    return requires;
}

fn binarySearch(map: *const Map, leftovers: *Leftovers, min: u64, max: u64) !u64 {
    var lo = min;
    var hi = max;
    while (lo < hi) {
        leftovers.clearRetainingCapacity();
        const mid = lo + (hi - lo + 1) / 2;
        if (try oreentating(map, "FUEL", mid, leftovers) <= 1_000_000_000_000) {
            lo = mid;
        } else hi = mid - 1;
    }
    return lo;
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
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

    var map = Map.init(allocator);
    defer {
        var vit = map.valueIterator();
        while (vit.next()) |e| e.*.requires.deinit();
        map.deinit();
    }

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |line| try parseLine(allocator, line, &map);

    var leftovers = Leftovers.init(allocator);
    defer leftovers.deinit();

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        try oreentating(&map, "FUEL", 1, &leftovers),
        try binarySearch(&map, &leftovers, 1, 100000000),
    });
}
