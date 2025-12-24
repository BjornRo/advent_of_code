const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d02.txt");
    defer alloc.free(data);

    const result = try solve(data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(data: []const u8) !struct { p1: usize, p2: usize } {
    var total1: usize = 0;
    var total2: usize = 0;

    var splitIter = std.mem.splitScalar(u8, data, '\n');
    while (splitIter.next()) |item| {
        const first = item[0] - 'A';
        const second = item[2] - 'X';
        total1 += second + 1 + @as(usize, if (first == second) 3 else if (@mod(second + 3 - first, 3) == 1) 6 else 0);
        total2 += second * 3 + 1 + switch (second) {
            0 => @mod(first + 2, 3),
            1 => @mod(first, 3),
            else => @mod(first + 1, 3),
        };
    }
    return .{ .p1 = total1, .p2 = total2 };
}
