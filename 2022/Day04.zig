const std = @import("std");
const utils = @import("utils.zig");

const Range = struct {
    start: u8,
    end: u8,

    const Self = @This();
    pub fn contains(self: Self, o: Self) bool {
        return self.start <= o.start and o.end <= self.end;
    }
    pub fn overlaps(self: Self, o: Self) bool {
        return o.start <= self.start and self.start <= o.end or (self.start <= o.start and o.start <= self.end);
    }
    pub fn init(string: []const u8) !Self {
        var splitIter = std.mem.splitScalar(u8, string, '-');
        return .{
            .start = try std.fmt.parseUnsigned(u8, splitIter.next().?, 10),
            .end = try std.fmt.parseUnsigned(u8, splitIter.next().?, 10),
        };
    }
};
pub fn main() !void {
    const start = std.time.microTimestamp();
    defer std.debug.print("Time: {any}s\n", .{@as(f64, @floatFromInt(std.time.microTimestamp() - start)) / 1000_000});

    const alloc = std.heap.smp_allocator;
    const data = try utils.read(alloc, "in/d04.txt");
    defer alloc.free(data);

    const result = try solve(data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}
fn solve(data: []const u8) !struct { p1: u16, p2: u16 } {
    var total1: u16 = 0;
    var total2: u16 = 0;
    var splitIter = std.mem.splitScalar(u8, data, '\n');
    while (splitIter.next()) |item| {
        var splitRow = std.mem.splitScalar(u8, item, ',');
        const r0 = try Range.init(splitRow.next().?);
        const r1 = try Range.init(splitRow.next().?);
        if (r0.contains(r1) or r1.contains(r0)) total1 += 1;
        if (r0.overlaps(r1)) total2 += 1;
    }
    return .{ .p1 = total1, .p2 = total2 };
}
