const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;
const Deque = @import("deque.zig").Deque;

const Set = std.AutoHashMap(Cube, void);
const Cube = struct {
    x: CT,
    y: CT,
    z: CT,
    id: usize,
    const CT = i32;
    const Self = @This();
    fn manhattan(self: Self, o: Self) usize {
        return @abs(self.x - o.x) + @abs(self.y - o.y) + @abs(self.z - o.z);
    }
};
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d18t.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var list: std.ArrayList(Cube) = .empty;
    defer list.deinit(alloc);
    {
        var i: usize = 0;
        var split_iter = std.mem.splitScalar(u8, data, '\n');
        while (split_iter.next()) |item| : (i += 1) {
            var number_iter = utils.NumberIter(i32).init(item);
            try list.append(alloc, .{ .id = i, .x = number_iter.next().?, .y = number_iter.next().?, .z = number_iter.next().? });
        }
    }

    // 10823 too high
    const total: usize = 0;
    var clusters: std.ArrayList(Set) = .empty;
    defer {
        for (clusters.items) |*set| set.deinit();
        clusters.deinit(alloc);
    }
    try clustering(alloc, &clusters, list.items);

    for (clusters.items) |set| {
        std.debug.print("{d}\n", .{set.count()});
    }

    return .{ .p1 = total, .p2 = 2 };
}

fn clustering(alloc: Allocator, clusters: *std.ArrayList(Set), cubes: []Cube) !void {
    var visited: std.AutoHashMap(usize, void) = .init(alloc);
    defer visited.deinit();

    while (true) {
        var i: i32 = @intCast(cubes.len - 1);
        var moved = false;
        outer: while (i >= 0) : (i -= 1) {
            var cube = cubes[@intCast(i)];
            if (visited.contains(cube.id)) continue;
            for (clusters.items) |*set| {
                var set_iter = set.keyIterator();
                while (set_iter.next()) |item| {
                    if (cube.manhattan(item.*) <= 1) {
                        try set.put(cube, {});
                        moved = true;
                        try visited.put(cube.id, {});
                        continue :outer;
                    }
                }
            }
            var set: Set = .init(alloc);
            try set.put(cube, {});
            try visited.put(cube.id, {});
            try clusters.append(alloc, set);
            moved = true;
        }
        if (!moved) break;
    }
}
