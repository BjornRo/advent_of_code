const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d03.txt");
    defer alloc.free(data);

    const result = try solve(data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn mapper(char: u8) usize {
    return switch (char) {
        'a'...'z' => char - 96,
        else => char - 38,
    };
}

fn solve(data: []const u8) !struct { p1: usize, p2: usize } {
    var total1: usize = 0;
    var total2: usize = 0;
    var buffer: [3][]const u8 = undefined;
    var groups = std.ArrayList([]const u8).initBuffer(&buffer);
    var splitIter = std.mem.splitScalar(u8, data, '\n');
    while (splitIter.next()) |item| {
        const len = item.len;
        const first = item[0 .. len / 2];
        const second = item[len / 2 ..];
        for (first) |elem| {
            if (std.mem.containsAtLeastScalar(u8, second, 1, elem)) {
                total1 += mapper(elem);
                break;
            }
        }
        groups.appendAssumeCapacity(item);
        if (groups.items.len == 3) {
            for (groups.items[0]) |elem| {
                if (std.mem.containsAtLeastScalar(u8, groups.items[1], 1, elem) and
                    std.mem.containsAtLeastScalar(u8, groups.items[2], 1, elem))
                {
                    total2 += mapper(elem);
                    break;
                }
            }
            groups.clearRetainingCapacity();
        }
    }
    return .{ .p1 = total1, .p2 = total2 };
}
