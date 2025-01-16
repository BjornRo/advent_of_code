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

const CT = i16;
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
    fn update(self: *Self, o: Point) void {
        self.row += o.row;
        self.col += o.col;
    }
    fn mul(self: Point, other: Point) Point {
        return Point.init(self.row * other.row - self.col * other.col, self.row * other.col + self.col * other.row);
    }
    fn toArr(self: Self) [2]CT {
        return .{ self.row, self.col };
    }
    const HashCtx = struct {
        pub fn hash(_: @This(), key: Self) u32 {
            return std.hash.uint32(@as(u32, @bitCast(key.toArr())));
        }
        pub fn eql(_: @This(), a: Self, b: Self, _: usize) bool {
            return a.eq(b);
        }
    };
};

const Map = std.ArrayHashMap(Point, void, Point.HashCtx, true);
const ENHANCE = 9;

pub fn bresenham_collision(grid: Map, a: Point, b: Point) ?Point {
    const drow: CT = @intCast(@abs(b.row - a.row));
    const dcol: CT = -@as(CT, @intCast(@abs(b.col - a.col)));
    const srow: CT = if (a.row < b.row) 1 else -1;
    const scol: CT = if (a.col < b.col) 1 else -1;

    var point = a;
    var err = drow + dcol;
    while (true) {
        const e2 = 2 * err;
        if (e2 >= dcol) {
            err += dcol;
            point.row += srow;
        }
        if (e2 <= drow) {
            err += drow;
            point.col += scol;
        }
        if (point.eq(b)) break;
        if (grid.contains(point)) return point;
    }
    return null;
}

// The 1st asteroid to be vaporized is at 11,12.
// The 2nd asteroid to be vaporized is at 12,1.
// The 3rd asteroid to be vaporized is at 12,2.
// The 10th asteroid to be vaporized is at 12,8.
// The 20th asteroid to be vaporized is at 16,0.
// The 50th asteroid to be vaporized is at 16,9.
// The 100th asteroid to be vaporized is at 10,16.
// The 199th asteroid to be vaporized is at 9,6.
// The 200th asteroid to be vaporized is at 8,2.
// The 201st asteroid to be vaporized is at 10,9.
// The 299th and final asteroid to be vaporized is at 11,1.
fn part2(grid: *Map, grid_dim: CT, station_point: Point) !void {
    var laser_aim: Point = Point.init(0, station_point.col);
    var direction = Point.init(@divExact(ENHANCE, 3) * 2, ENHANCE);

    var vaporized: u16 = 0;
    while (true) {
        if (bresenham_collision(grid.*, station_point, laser_aim)) |point| {
            print(laser_aim);
            _ = grid.swapRemove(point);
            vaporized += 1;
            if (vaporized == 10) {
                break;
            }
            // print(point);
            // std.debug.print("vapor: {d}: {d},{d}\n", .{
            //     vaporized,
            //     point.row,
            //     point.col,
            //     // @divExact(point.col, ENHANCE),
            //     // @divExact(point.row, ENHANCE),
            // });
            std.debug.print("vapor {d}: {d},{d}\n", .{
                vaporized,
                @divExact(point.col, ENHANCE),
                @divExact(point.row, ENHANCE),
            });
        }
        const next_pos = laser_aim.add(direction);
        if (!(0 <= next_pos.row and next_pos.row < grid_dim and
            0 <= next_pos.col and next_pos.col < grid_dim))
        {
            direction = direction.mul(Point.init(0, -1));
        }
        laser_aim.update(direction);
    }

    // var max_visible: usize = 0;
    // for (point_list) |p0| {
    //     var total: u16 = 0;
    //     for (point_list) |p1| {
    //         if (p0.eq(p1)) continue;

    //         if (!bresenham_collision(&grid, p0, p1)) total += 1;
    //     }
    //     if (total > max_visible) {
    //         max_visible = total;
    //         // print(p0);
    //     }
    //     // print(total);
    // }
}

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d10t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var grid = Map.init(allocator);
    defer grid.deinit();

    var i: CT = 0;
    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        for (row, 0..) |e, j| {
            if (e != '.') try grid.put(Point.init(i * ENHANCE, @intCast(j * ENHANCE)), {});
        }
        i += 1;
    }
    const stats = try part1(grid);
    print(stats);
    _ = try part2(&grid, @intCast(input_attributes.row_len * ENHANCE), stats.point);
}

fn part1(grid: Map) !struct { visible: u16, point: Point } {
    var station_point: Point = undefined;
    var max_visible: u16 = 0;
    for (grid.keys()) |p0| {
        var total: u16 = 0;
        for (grid.keys()) |p1| {
            if (!p0.eq(p1) and bresenham_collision(grid, p0, p1) == null) total += 1;
        }
        if (total > max_visible) {
            max_visible = total;
            station_point = p0;
        }
    }
    return .{ .visible = max_visible, .point = station_point };
}
