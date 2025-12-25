const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const Set = std.AutoHashMap(struct { isize, isize }, void);

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d09.txt");
    defer alloc.free(data);

    std.debug.print("Part 1: {d}\n", .{try solve(alloc, data, 2)});
    std.debug.print("Part 2: {d}\n", .{try solve(alloc, data, 10)});
}
const Node = struct {
    row: isize = 0,
    col: isize = 0,
    parent: ?*Self,
    child: ?*Self,

    const Self = @This();
    fn init(alloc: Allocator, parent: ?*Self, child: ?*Self) !*Self {
        var new = try alloc.create(Self);
        new.parent = parent;
        new.child = child;
        return new;
    }
    fn deinit(self: *Self, alloc: Allocator) void {
        if (self.child) |c| c.deinit(alloc);
        alloc.destroy(self);
    }
    fn follow(self: *Self, p: *Self) void {
        const dr = p.row - self.row;
        const dc = p.col - self.col;
        if (@abs(dr) > 1 or @abs(dc) > 1) {
            self.row += std.math.sign(dr);
            self.col += std.math.sign(dc);
        }
    }
    fn right(self: *Self, visited: *Set) !void {
        if (self.parent) |p| self.follow(p) else self.col += 1;
        if (self.child) |c| try c.right(visited) else try visited.put(.{ self.row, self.col }, {});
    }
    fn left(self: *Self, visited: *Set) !void {
        if (self.parent) |p| self.follow(p) else self.col -= 1;
        if (self.child) |c| try c.left(visited) else try visited.put(.{ self.row, self.col }, {});
    }
    fn up(self: *Self, visited: *Set) !void {
        if (self.parent) |p| self.follow(p) else self.row -= 1;
        if (self.child) |c| try c.left(visited) else try visited.put(.{ self.row, self.col }, {});
    }
    fn down(self: *Self, visited: *Set) !void {
        if (self.parent) |p| self.follow(p) else self.row += 1;
        if (self.child) |c| try c.left(visited) else try visited.put(.{ self.row, self.col }, {});
    }
};
fn solve(alloc: Allocator, data: []const u8, tail_len: usize) !usize {
    var splitIter = std.mem.splitScalar(u8, data, '\n');

    var visited = Set.init(alloc);
    defer visited.deinit();

    const head = blk: {
        const head = try Node.init(alloc, null, null);
        var curr: ?*Node = head;
        for (0..tail_len - 1) |_| {
            const next = try Node.init(alloc, curr, null);
            if (curr) |c| c.child = next;
            curr = next;
        }
        break :blk head;
    };
    defer head.deinit(alloc);

    while (splitIter.next()) |item| {
        var rowIter = std.mem.splitScalar(u8, item, ' ');
        const dir = rowIter.next().?[0];
        for (0..try std.fmt.parseUnsigned(u8, rowIter.next().?, 10)) |_| switch (dir) {
            'R' => try head.right(&visited),
            'L' => try head.left(&visited),
            'U' => try head.up(&visited),
            else => try head.down(&visited),
        };
    }

    return visited.count();
}
