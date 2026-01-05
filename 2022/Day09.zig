const std = @import("std");
const utils = @import("utils.zig");

const Vec2 = @Vector(2, i16);
const Set = std.AutoHashMap(Vec2, void);
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const alloc, const is_debug = switch (@import("builtin").mode) {
        .Debug => .{ debug_allocator.allocator(), true },
        else => .{ std.heap.smp_allocator, false },
    };
    const start = std.time.microTimestamp();
    defer {
        std.debug.print("Time: {any}s\n", .{@as(f64, @floatFromInt(std.time.microTimestamp() - start)) / 1000_000});
        if (is_debug) _ = debug_allocator.deinit();
    }

    const data = try utils.read(alloc, "in/d09.txt");
    defer alloc.free(data);

    std.debug.print("Part 1: {d}\n", .{try solve(alloc, data, 2)});
    std.debug.print("Part 2: {d}\n", .{try solve(alloc, data, 10)});
}
const Node = struct {
    pos: Vec2 = .{ 0, 0 },
    idx: u8,

    const Self = @This();
    fn follow(self: *Self, rope: []Self) void {
        const diff = rope[self.idx - 1].pos - self.pos;
        if (@abs(diff[0]) > 1 or @abs(diff[1]) > 1) self.pos += std.math.sign(diff);
    }
    fn move(self: *Self, vis: *Set, rope: []Self, offset: Vec2) !void {
        if (self.idx != 0) self.follow(rope) else self.pos += offset;
        if (self.idx + 1 == rope.len) try vis.put(self.pos, {}) else try rope[self.idx + 1].move(vis, rope, offset);
    }
};
fn solve(alloc: std.mem.Allocator, data: []const u8, tail_len: u8) !usize {
    var rope = try alloc.alloc(Node, tail_len);
    defer alloc.free(rope);
    for (0..tail_len) |i| rope[i] = .{ .idx = @truncate(i) };

    var visited = Set.init(alloc);
    defer visited.deinit();

    var splitIter = std.mem.splitScalar(u8, data, '\n');
    while (splitIter.next()) |item| {
        const dir: Vec2 = switch (item[0]) {
            'R' => .{ 0, 1 },
            'L' => .{ 0, -1 },
            'U' => .{ -1, 0 },
            else => .{ 1, 0 },
        };
        for (0..try std.fmt.parseUnsigned(u8, item[2..], 10)) |_| try rope[0].move(&visited, rope, dir);
    }
    return visited.count();
}
