const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Allocator = std.mem.Allocator;

const ENHANCE = 9;
const CT = i16;
const Map = std.ArrayHashMap(Point, void, Point.HashCtx, true);
const Point = struct {
    row: CT,
    col: CT,

    const Self = @This();
    fn init(row: CT, col: CT) Self {
        return .{ .row = row, .col = col };
    }
    fn add(self: Self, o: Point) Point {
        return Self.init(self.row + o.row, self.col + o.col);
    }
    fn eq(self: Self, o: Point) bool {
        return self.row == o.row and self.col == o.col;
    }
    fn update(self: *Self, o: Point) void {
        self.row += o.row;
        self.col += o.col;
    }
    fn mul(self: Point, other: Point) Point {
        return Point.init(
            self.row * other.row - self.col * other.col,
            self.row * other.col + self.col * other.row,
        );
    }
    const HashCtx = struct {
        pub fn hash(_: @This(), key: Self) u32 {
            return std.hash.uint32(@bitCast([2]CT{ key.row, key.col }));
        }
        pub fn eql(_: @This(), a: Self, b: Self, _: usize) bool {
            return a.eq(b);
        }
    };
};

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

fn part2(allocator: Allocator, grid: *Map, grid_dim: CT, station_point: Point) !CT {
    var visited = Map.init(allocator);
    defer visited.deinit();

    const FACTOR = grid_dim * ENHANCE * 5;
    const min_laser_row = station_point.row - FACTOR;
    const max_laser_row = station_point.row + FACTOR;
    const min_laser_col = station_point.col - FACTOR;
    const max_laser_col = station_point.col + FACTOR;

    const laser_start = Point.init(min_laser_row, station_point.col);
    var laser_aim: Point = laser_start;
    var direction = Point.init(0, 1);

    var vaporized: u16 = 0;
    while (true) {
        if (laser_start.eq(laser_aim)) {
            for (visited.keys()) |point| {
                _ = grid.swapRemove(point);
                vaporized += 1;
                if (vaporized == 200)
                    return @divExact(point.col, ENHANCE) * 100 + @divExact(point.row, ENHANCE);
            }
            visited.clearRetainingCapacity();
        }
        if (bresenham_collision(grid.*, station_point, laser_aim)) |point| {
            if (!visited.contains(point)) try visited.put(point, {});
        }
        const next_pos = laser_aim.add(direction);
        if (!(min_laser_row <= next_pos.row and next_pos.row < max_laser_row and
            min_laser_col <= next_pos.col and next_pos.col < max_laser_col))
        {
            direction = direction.mul(Point.init(0, -1));
        }
        laser_aim.update(direction);
    }
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [70_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

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
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        stats.visible,
        try part2(allocator, &grid, @intCast(input_attributes.row_len), stats.point),
    });
}
