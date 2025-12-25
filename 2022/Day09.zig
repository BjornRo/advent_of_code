const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const Set = std.AutoHashMap(struct { isize, isize }, void);

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d09t.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}
fn delta(hrow: isize, hcol: isize, trow: isize, tcol: isize) isize {
    const dr = if (hrow >= trow) hrow - trow else trow - hrow;
    const dc = if (hcol >= tcol) hcol - tcol else tcol - hcol;
    return if (dr > dc) dr else dc;
}
fn valid(hrow: isize, hcol: isize, trow: isize, tcol: isize) bool {
    return delta(hrow, hcol, trow, tcol) <= 1;
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
    fn right(self: *Self, visited: *Set) !void {
        if (self.parent) |p| {
            if (!p.valid(self)) {
                self.col = p.col - 1;
                self.row = p.row;
            }
            try visited.put(.{ self.row, self.col }, {});
        }
        self.col += 1;
        if (self.child) |c| c.right(visited);
    }
    fn left(self: *Self, visited: *Set) !void {
        if (self.parent) |p| {
            if (!p.valid(self)) {
                self.col = p.col + 1;
                self.row = p.row;
            }
            try visited.put(.{ self.row, self.col }, {});
        }
        self.col -= 1;
        if (self.child) |c| c.left(visited);
    }
    fn up(self: *Self, visited: *Set) !void {
        if (self.parent) |p| {
            if (!p.valid(self)) {
                self.row = p.row + 1;
                self.col = p.col;
            }
            try visited.put(.{ self.row, self.col }, {});
        }
        self.row -= 1;
        if (self.child) |c| c.up(visited);
    }
    fn down(self: *Self, visited: *Set) !void {
        if (self.parent) |p| {
            if (!p.valid(self)) {
                self.row = p.row - 1;
                self.col = p.col;
            }
            try visited.put(.{ self.row, self.col }, {});
        }
        self.row += 1;
        if (self.child) |c| c.up(visited);
    }
    fn valid(self: Self, child: *Self) bool {
        return delta(self.row, self.col, child.row, child.col) <= 1;
    }
    fn deinit(self: *Self, alloc: Allocator) void {
        if (self.child) |c| c.deinit();
        alloc.destroy(self);
    }
};
fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var splitIter = std.mem.splitScalar(u8, data, '\n');

    var visited = Set.init(alloc);
    defer visited.deinit();

    const head = blk: {
        const head = try Node.init(alloc, null, null);
        var curr: ?*Node = head;
        for (0..2) |_| {
            const next = try Node.init(alloc, curr, null);
            curr = next;
        }
        break :blk head;
    };

    var head_row: isize = 0;
    var head_col: isize = 0;
    var tail_row: isize = 0;
    var tail_col: isize = 0;
    while (splitIter.next()) |item| {
        var rowIter = std.mem.splitBackwardsScalar(u8, item, ' ');
        const value = try std.fmt.parseUnsigned(u8, rowIter.next().?, 10);
        switch (rowIter.next().?[0]) {
            'R' => {
                for (0..value) |_| {
                    head_col += 1;
                    if (!valid(head_row, head_col, tail_row, tail_col)) {
                        tail_col = head_col - 1;
                        tail_row = head_row;
                    }
                    try visited.put(.{ tail_row, tail_col }, {});
                }
            },
            'L' => {
                for (0..value) |_| {
                    head_col -= 1;
                    if (!valid(head_row, head_col, tail_row, tail_col)) {
                        tail_col = head_col + 1;
                        tail_row = head_row;
                    }
                    try visited.put(.{ tail_row, tail_col }, {});
                }
            },
            'U' => {
                for (0..value) |_| {
                    head_row -= 1;
                    if (!valid(head_row, head_col, tail_row, tail_col)) {
                        tail_row = head_row + 1;
                        tail_col = head_col;
                    }
                    try visited.put(.{ tail_row, tail_col }, {});
                }
            },
            else => {
                for (0..value) |_| {
                    head_row += 1;
                    if (!valid(head_row, head_col, tail_row, tail_col)) {
                        tail_row = head_row - 1;
                        tail_col = head_col;
                    }
                    try visited.put(.{ tail_row, tail_col }, {});
                }
            },
        }
    }

    return .{ .p1 = visited.count(), .p2 = 2 };
}
