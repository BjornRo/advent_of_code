const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const CT = i64;
const Key = u12;
const Op = enum { Add, Sub, Mul, Div };
const Value = union(enum) {
    value: CT,
    op: struct { op: Op, left: Key, right: Key },
};
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d21.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}
fn solve(alloc: Allocator, data: []const u8) !struct { p1: CT, p2: CT } {
    const start, const humn, const graph = blk: {
        var map: std.StringHashMap(Key) = .init(alloc);
        defer map.deinit();
        var parsing_step: std.ArrayList(struct { key: []const u8, value: []const u8 }) = .empty;
        defer parsing_step.deinit(alloc);
        {
            var k: Key = 0;
            var split_iter = std.mem.splitScalar(u8, data, '\n');
            while (split_iter.next()) |row| : (k += 1) {
                const split_point = std.mem.indexOfScalar(u8, row, ':').?;
                try parsing_step.append(alloc, .{ .key = row[0..split_point], .value = row[split_point + 2 ..] });
                try map.put(row[0..split_point], k);
            }
        }
        var buffer: [3][]const u8 = undefined;
        var tmp: std.ArrayList([]const u8) = .initBuffer(&buffer);
        var graph = try alloc.alloc(Value, parsing_step.items.len);
        for (parsing_step.items) |item| {
            tmp.clearRetainingCapacity();
            var iter = std.mem.splitScalar(u8, item.value, ' ');
            while (iter.next()) |e| tmp.appendAssumeCapacity(e);
            graph[map.get(item.key).?] = if (tmp.items.len == 1)
                .{ .value = try std.fmt.parseInt(CT, tmp.items[0], 10) }
            else
                .{ .op = .{
                    .op = switch (tmp.items[1][0]) {
                        '+' => .Add,
                        '-' => .Sub,
                        '/' => .Div,
                        else => .Mul,
                    },
                    .left = map.get(tmp.items[0]).?,
                    .right = map.get(tmp.items[2]).?,
                } };
        }
        break :blk .{ map.get("root").?, map.get("humn").?, graph };
    };
    defer alloc.free(graph);
    return .{ .p1 = traverse(graph, start), .p2 = part2(graph, start, humn) };
}
fn part2(graph: []Value, node: Key, humn: Key) CT {
    const left = graph[node].op.left;
    const right = graph[node].op.right;
    const MetaInt = std.meta.Int(.unsigned, @typeInfo(CT).int.bits);
    var low: MetaInt = 0;
    var high: MetaInt = 1;
    while (traverse(graph, left) > traverse(graph, right)) : (high *= 2) graph[humn].value = @intCast(high);
    while (true) {
        var mid = low + (high - low) / 2;
        graph[humn].value = @intCast(mid);
        const r0 = traverse(graph, left);
        const r1 = traverse(graph, right);
        if (r0 == r1) {
            while (traverse(graph, left) == traverse(graph, right)) : (mid -= 1) graph[humn].value = @intCast(mid);
            return @intCast(mid + 2);
        } else if (r0 > r1) low = mid + 1 else high = mid;
    }
}
fn traverse(graph: []Value, node: Key) CT {
    return switch (graph[node]) {
        .value => |v| v,
        .op => |e| switch (e.op) {
            .Add => traverse(graph, e.left) + traverse(graph, e.right),
            .Sub => traverse(graph, e.left) - traverse(graph, e.right),
            .Mul => traverse(graph, e.left) * traverse(graph, e.right),
            .Div => @divFloor(traverse(graph, e.left), traverse(graph, e.right)),
        },
    };
}
