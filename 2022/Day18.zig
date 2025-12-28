const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const CT = i32;
const Set = std.AutoArrayHashMap(Cube, void);
const Cube = struct {
    x: CT,
    y: CT,
    z: CT,
    const Self = @This();
    fn manhattan(self: Self, o: Self) usize {
        return @abs(self.x - o.x) + @abs(self.y - o.y) + @abs(self.z - o.z);
    }
};
const dirs = [_][3]CT{
    .{ 1, 0, 0 }, .{ -1, 0, 0 },
    .{ 0, 1, 0 }, .{ 0, -1, 0 },
    .{ 0, 0, 1 }, .{ 0, 0, -1 },
};
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d18.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var set: Set = .init(alloc);
    defer set.deinit();

    var split_iter = std.mem.splitScalar(u8, data, '\n');
    while (split_iter.next()) |item| {
        var number_iter = utils.NumberIter(i32).init(item);
        try set.put(.{
            .x = number_iter.next().?,
            .y = number_iter.next().?,
            .z = number_iter.next().?,
        }, {});
    }

    const total = countSurface(set.keys());
    return .{ .p1 = total, .p2 = total - try part2(alloc, set) };
}
fn countSurface(slice: anytype) usize {
    var total = slice.len * 6;
    for (0..slice.len) |i| for (0..slice.len) |j| {
        if (slice[i].manhattan(slice[j]) == 1) total -= 1;
    };
    return total;
}
fn findSpace(alloc: Allocator, set: Set, cube: Cube, min_x: CT, max_x: CT, min_y: CT, max_y: CT, min_z: CT, max_z: CT) !?Set {
    var visited: Set = .init(alloc);
    var stack: std.ArrayList(Cube) = .empty;
    try stack.append(alloc, cube);
    defer stack.deinit(alloc);
    while (stack.pop()) |next| {
        if (next.x < min_x or next.x > max_x or next.y < min_y or next.y > max_y or next.z < min_z or next.z > max_z) {
            visited.deinit();
            return null;
        }
        if (set.contains(next)) continue;
        const res = try visited.getOrPut(next);
        if (res.found_existing) continue;
        res.key_ptr.* = next;
        for (dirs) |d| try stack.append(alloc, .{ .x = next.x + d[0], .y = next.y + d[1], .z = next.z + d[2] });
    }
    return visited;
}
fn part2(alloc: Allocator, set: Set) !usize {
    var min_x: CT = std.math.maxInt(CT);
    var max_x: CT = std.math.minInt(CT);
    var min_y: CT = std.math.maxInt(CT);
    var max_y: CT = std.math.minInt(CT);
    var min_z: CT = std.math.maxInt(CT);
    var max_z: CT = std.math.minInt(CT);
    for (set.keys()) |cube| {
        min_x = @min(min_x, cube.x);
        max_x = @max(max_x, cube.x);
        min_y = @min(min_y, cube.y);
        max_y = @max(max_y, cube.y);
        min_z = @min(min_z, cube.z);
        max_z = @max(max_z, cube.z);
    }
    var visited: Set = .init(alloc);
    defer visited.deinit();
    for (@intCast(min_x)..@intCast(max_x + 1)) |x|
        for (@intCast(min_y)..@intCast(max_y + 1)) |y|
            for (@intCast(min_z)..@intCast(max_z + 1)) |z| {
                const new: Cube = .{ .x = @intCast(x), .y = @intCast(y), .z = @intCast(z) };
                if (visited.contains(new)) continue;
                if (set.contains(new)) continue;
                if (try findSpace(alloc, set, new, min_x, max_x, min_y, max_y, min_z, max_z)) |points| {
                    var pset = points;
                    defer pset.deinit();
                    for (points.keys()) |c| try visited.put(c, {});
                }
            };
    return countSurface(visited.keys());
}
