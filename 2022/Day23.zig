const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const CT = i16;
const Dir = enum { North, South, West, East };
const Elf = struct { dir: ?Dir };
const Set = std.AutoArrayHashMap(struct { i: CT, j: CT }, ?Dir);
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d23.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}
fn solve(alloc: Allocator, data: []u8) !struct { p1: usize, p2: usize } {
    var set = blk: {
        const matrix = utils.arrayToMatrix(data);
        var set: Set = .init(alloc);
        for (0..matrix.rows) |i| for (0..matrix.cols) |j|
            if (matrix.get(i, j) == '#') try set.put(.{ .i = @intCast(i), .j = @intCast(j) }, null);
        break :blk set;
    };
    defer set.deinit();
    var cset = try set.clone();
    defer cset.deinit();
    return .{ .p1 = try mover(alloc, &cset, 10), .p2 = try mover(alloc, &set, 10000) };
}
fn assignAction(set: *Set, dirs: []Dir, row: CT, col: CT) ?Dir {
    for (utils.getKernel3x3(CT, row, col)) |nb|
        if (set.contains(.{ .i = nb[0], .j = nb[1] })) {
            for (dirs) |dir| {
                const offsets: [3][2]CT = switch (dir) {
                    .North => .{ .{ -1, -1 }, .{ -1, 0 }, .{ -1, 1 } },
                    .South => .{ .{ 1, -1 }, .{ 1, 0 }, .{ 1, 1 } },
                    .West => .{ .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 } },
                    .East => .{ .{ -1, 1 }, .{ 0, 1 }, .{ 1, 1 } },
                };
                for (offsets) |i| {
                    if (set.contains(.{ .i = row + i[0], .j = col + i[1] })) break;
                } else return dir;
            }
            break;
        };
    return null;
}
fn mover(alloc: Allocator, set: *Set, rounds: usize) !usize {
    var tmp: Set = .init(alloc);
    defer tmp.deinit();

    var proposal: std.AutoArrayHashMap(struct { i: CT, j: CT }, usize) = .init(alloc);
    defer proposal.deinit();

    var dirs: [4]Dir = undefined;
    var list: std.ArrayList(Dir) = .initBuffer(&dirs);
    list.appendSliceAssumeCapacity(&[_]Dir{ .North, .South, .West, .East });

    for (1..rounds + 1) |i| {
        defer {
            std.mem.swap(Set, set, &tmp);
            tmp.clearRetainingCapacity();
            proposal.clearRetainingCapacity();
            list.appendAssumeCapacity(list.orderedRemove(0));
        }
        var moved = false;
        for (set.keys(), set.values()) |k, *v| {
            v.* = assignAction(set, &dirs, k.i, k.j);
            if (v.*) |dir| {
                var row = k.i;
                var col = k.j;
                switch (dir) {
                    .North => row -= 1,
                    .South => row += 1,
                    .West => col -= 1,
                    .East => col += 1,
                }
                const res = try proposal.getOrPut(.{ .i = row, .j = col });
                if (res.found_existing) res.value_ptr.* += 1 else res.value_ptr.* = 1;
            }
        }
        for (set.keys(), set.values()) |k, *v| {
            var row = k.i;
            var col = k.j;
            if (v.*) |dir| switch (dir) {
                .North => row -= 1,
                .South => row += 1,
                .West => col -= 1,
                .East => col += 1,
            };
            if (proposal.get(.{ .i = row, .j = col })) |res|
                if (res != 1) {
                    row = k.i;
                    col = k.j;
                } else {
                    moved = true;
                };
            try tmp.put(.{ .i = row, .j = col }, null);
        }
        if (!moved) return i;
    }
    var min_row: CT = std.math.maxInt(CT);
    var min_col: CT = std.math.maxInt(CT);
    var max_row: CT = std.math.minInt(CT);
    var max_col: CT = std.math.minInt(CT);
    for (set.keys()) |k| {
        min_row = @min(min_row, k.i);
        min_col = @min(min_col, k.j);
        max_row = @max(max_row, k.i);
        max_col = @max(max_col, k.j);
    }
    var total: usize = 0;
    for (0..@intCast(max_row - min_row + 1)) |i| for (0..@intCast(max_col - min_col + 1)) |j| {
        const ii: CT = @intCast(i);
        const jj: CT = @intCast(j);
        if (!set.contains(.{ .i = ii + min_row, .j = jj + min_col })) total += 1;
    };
    return total;
}
