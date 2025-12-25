const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

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
fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var splitIter = std.mem.splitScalar(u8, data, '\n');

    var visited = std.AutoHashMap(struct { isize, isize }, void).init(alloc);
    defer visited.deinit();

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
