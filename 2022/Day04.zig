const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const Range = struct {
    start: u8,
    end: u8,

    const Self = @This();
    pub fn Contains(self: Self, o: Self) bool {
        return self.start <= o.start and o.end <= self.end;
    }
    pub fn Overlaps(self: Self, o: Self) bool {
        return o.start <= self.start and self.start <= o.end or (self.start <= o.start and o.start <= self.end);
    }
    pub fn Init(string: []const u8) !Self {
        var splitIter = std.mem.splitScalar(u8, string, '-');
        return .{
            .start = try std.fmt.parseUnsigned(u8, splitIter.next().?, 10),
            .end = try std.fmt.parseUnsigned(u8, splitIter.next().?, 10),
        };
    }
};

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d04.txt");
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
        var splitRow = std.mem.splitScalar(u8, item, ',');
        const r0 = try Range.Init(splitRow.next().?);
        const r1 = try Range.Init(splitRow.next().?);
        if (r0.Contains(r1) or r1.Contains(r0)) total1 += 1;
        if (r0.Overlaps(r1)) total2 += 1;
    }
    return .{ .p1 = total1, .p2 = total2 };
}
