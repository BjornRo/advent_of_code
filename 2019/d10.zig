const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    // const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    // std.debug.print("{s}\n", .{input});
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}

const CT = i8;
const Point = struct {
    row: CT,
    col: CT,

    const Self = @This();
    fn init(row: CT, col: CT) Self {
        return .{ .row = row, .col = col };
    }
    fn eq(self: Self, o: Point) bool {
        return self.row == o.row and self.col == o.col;
    }
    fn add(self: Self, o: Point) Point {
        return Self.init(self.row + o.row, self.col + o.col);
    }
    fn toArr(self: Self) [2]CT {
        return .{ self.row, self.col };
    }
    fn hash(self: Self) u64 {
        // return std.hash.CityHash64.hash(&@as([2]u8, @bitCast(self.toArr())));
        return @intCast(std.hash.uint32(@as(u16, @bitCast(self.toArr()))));
    }
};

const Map = std.HashMap(Point, void, HashCtx, 80);
const PointList = std.ArrayList(Point);

const HashCtx = struct {
    pub fn hash(_: @This(), key: Point) u64 {
        return key.hash();
    }
    pub fn eql(_: @This(), a: Point, b: Point) bool {
        return a.eq(b);
    }
};

pub fn bresenham(allocator: Allocator, a: Point, b: Point) !PointList {
    var ra, var ca = a.toArr();
    const rb, const cb = b.toArr();

    const dr: CT = -@as(CT, @intCast(@abs(rb - ra)));
    const dc: CT = @as(CT, @intCast(@abs(cb - ca)));
    const sr: CT = if (ra < rb) 1 else -1;
    const sc: CT = if (ca < cb) 1 else -1;

    var err = dr + dc;

    var points = PointList.init(allocator);
    while (true) {
        try points.append(Point.init(ra, ca));

        if (ra == rb and ca == cb) break;
        const e2 = err * 2;
        if (e2 >= dc) {
            if (ra == rb) break; // maybe remove
            err += dc;
            ra += sr;
        }
        if (e2 <= dr) {
            if (ca == cb) break; // maybe remove
            err += dr;
            ca += sc;
        }
    }

    return points;
}

fn part1(allocator: Allocator, point_list: []const Point) !void {
    const p = Point.init(0, 0);

    var grid = Map.init(allocator);
    defer grid.deinit();
    for (point_list) |point| try grid.put(point, {});

    var total: u16 = 0;
    for (point_list) |point| {
        if (p.eq(point)) continue;

        const line = try bresenham(allocator, p, point);
        defer line.deinit();

        for (line.items) |line_p| {
            if (line_p.eq(p)) continue;
            if (grid.contains(line_p)) break;
        } else {
            total += 1;
        }
    }
    print(total);
}

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d10t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var point_list = PointList.init(allocator);
    defer point_list.deinit();

    var i: i8 = 0;
    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        for (row, 0..) |e, j| {
            if (e != '.') try point_list.append(Point.init(i, @intCast(j)));
        }
        i += 1;
    }
    try part1(allocator, point_list.items);
}
