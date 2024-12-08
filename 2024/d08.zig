const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const Point = packed struct {
    row: i8,
    col: i8,

    const Self = @This();
    fn delta(self: Self, o: Self) struct { dr: i8, dc: i8 } {
        return .{
            .dr = o.row - self.row, // Assuming that o is always after self.
            .dc = o.col - self.col,
        };
    }
    fn validCPMove(self: Self, dRow: i8, dCol: i8, neg: bool, rows: i8, cols: i8) ?Self {
        const move = if (neg)
            .{ .row = self.row - dRow, .col = self.col - dCol }
        else
            .{ .row = self.row + dRow, .col = self.col + dCol };
        return if ((0 <= move.row and move.row < rows) and (0 <= move.col and move.col < cols)) move else null;
    }
};

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    // const allocator = gpa.allocator();
    var buffer: [59_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input = @embedFile("in/d08.txt");
    // End setup

    const input_attributes = try myf.getDelimType(input);

    const cols: i8 = @intCast(input_attributes.row_len);
    var rows: i8 = 0;

    var symbol_points = std.AutoArrayHashMap(u8, std.ArrayList(Point)).init(allocator);
    defer symbol_points.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, if (input_attributes.delim == .CRLF) "\r\n" else "\n");
    while (in_iter.next()) |row| {
        defer rows += 1;
        for (row, 0..) |elem, j| {
            if (elem == '.') continue;
            const res = try symbol_points.getOrPut(elem);
            if (!res.found_existing) res.value_ptr.* = std.ArrayList(Point).init(allocator);
            try res.value_ptr.*.append(.{ .row = rows, .col = @intCast(j) });
        }
    }

    var unique_points = std.AutoArrayHashMap(Point, void).init(allocator);
    defer unique_points.deinit();

    var unique_points_rep = std.AutoArrayHashMap(Point, void).init(allocator);
    defer unique_points_rep.deinit();

    var symbol_iter = symbol_points.iterator();
    while (symbol_iter.next()) |entry| {
        defer entry.value_ptr.*.deinit();

        var points = entry.value_ptr.*.items;
        for (points[0 .. points.len - 1], 1..) |p0, i| {
            for (points[i..points.len]) |p1| {
                const d = p0.delta(p1);

                for ([_]bool{ true, false }, [_]Point{ p0, p1 }) |b, p| {
                    try unique_points_rep.put(p, {});

                    var new_p = p.validCPMove(d.dr, d.dc, b, rows, cols);
                    if (new_p) |valid_p| try unique_points.put(valid_p, {}) else continue;

                    while (new_p) |valid_p| {
                        try unique_points_rep.put(valid_p, {});
                        new_p = valid_p.validCPMove(d.dr, d.dc, b, rows, cols);
                    }
                }
            }
        }
    }
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        unique_points.count(),
        unique_points_rep.count(),
    });
}
