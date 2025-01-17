const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const NameValue = struct {
    value: u32,
    name: []const u8,
};
const RequireList = std.ArrayList(NameValue);
const ProductionMap = struct {
    produces: u32,
    requires: std.ArrayList(NameValue),
};
// const Result = struct { ore: u32, remainder: std.StringHashMap(usize) };
const Leftovers = std.StringHashMap(u32);
const Map = std.StringHashMap(ProductionMap);

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
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

fn parseElement(raw_elem: []const u8) !NameValue {
    var elem_it = std.mem.tokenizeScalar(u8, raw_elem, ' ');
    const value = try std.fmt.parseInt(u32, elem_it.next().?, 10);
    return .{ .name = elem_it.next().?, .value = value };
}

fn parseLine(allocator: Allocator, line: []const u8, map: *Map) !void {
    var line_it = std.mem.tokenizeSequence(u8, line, " => ");
    const raw_left = line_it.next().?;
    var requires = RequireList.init(allocator);
    if (std.mem.indexOfScalar(u8, raw_left, ',') == null) {
        try requires.append(try parseElement(raw_left));
    } else {
        var left_iter = std.mem.tokenizeSequence(u8, raw_left, ", ");
        while (left_iter.next()) |elem| try requires.append(try parseElement(elem));
    }
    const right = try parseElement(line_it.next().?);
    try map.put(right.name, .{ .produces = right.value, .requires = requires });
}

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d14t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var map = Map.init(allocator);
    defer {
        var vit = map.valueIterator();
        while (vit.next()) |e| e.*.requires.deinit();
        map.deinit();
    }

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |line| try parseLine(allocator, line, &map);

    // print(map.get("FUEL"));
    var leftovers = Leftovers.init(allocator);
    defer leftovers.deinit();

    print(try dfs(allocator, &map, "FUEL", 1, &leftovers));
}

fn calc_factor(requires: u32, produces: u32) u32 {
    return (requires + produces - 1) / requires;
}

fn dfs(allocator: Allocator, map: *const Map, symbol: []const u8, requires: u32, leftovers: *Leftovers) !u32 {
    if (map.get(symbol)) |production_map| {
        var ores: u32 = 0;
        const produces = production_map.produces;

        const requires_list = production_map.requires.items;
        for (requires_list) |requirement| {
            const leftover = leftovers.get(requirement.name) orelse 0;
            if (leftover >= requirement.value) {
                try leftovers.put(requirement.name, leftover - requirement.value);
            } else {
                const adj_requires = requires - leftover;
                const factor = (adj_requires + produces - 1) / produces;
                const total_requires = factor * requirement.value;
                try leftovers.put(requirement.name, produces * factor - adj_requires);
                ores += try dfs(allocator, map, requirement.name, total_requires, leftovers);
            }
        }
        return ores;
    }
    print(requires);
    return requires;
}
