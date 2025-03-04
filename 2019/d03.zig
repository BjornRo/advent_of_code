const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Allocator = std.mem.Allocator;

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
    fn toArr(self: Self) [2]CT {
        return .{ self.row, self.col };
    }
    fn hash(self: Self) u64 {
        return std.hash.CityHash64.hash(&@as([4]u8, @bitCast(self.toArr())));
    }
};

const PointHashCtx = struct {
    pub fn hash(_: @This(), key: Point) u64 {
        return key.hash();
    }
    pub fn eql(_: @This(), a: Point, b: Point) bool {
        return a.eq(b);
    }
};
const HashMap = std.HashMap(Point, usize, PointHashCtx, 90);

fn solver(allocator: Allocator, steps: [2][]const []const u8) ![2]usize {
    var visited = HashMap.init(allocator);
    defer visited.deinit();

    var p1_result = ~@as(usize, 0);
    var p2_result = ~@as(usize, 0);

    for (steps, 0..) |sub_steps, i| {
        var count: usize = 0;
        var pos = Point.init(0, 0);
        for (sub_steps) |step| {
            const direction = switch (step[0]) {
                'U' => Point.init(-1, 0),
                'D' => Point.init(1, 0),
                'R' => Point.init(0, 1),
                'L' => Point.init(0, -1),
                else => unreachable,
            };
            for (0..try std.fmt.parseInt(u16, step[1..], 10)) |_| {
                count += 1;
                pos = pos.add(direction);
                if (i == 0) {
                    try visited.put(pos, count);
                    continue;
                }
                if (visited.contains(pos)) {
                    var res: usize = @intCast(myf.manhattan(.{ 0, 0 }, pos.toArr()));
                    if (res < p1_result) p1_result = res;
                    res = visited.get(pos).? + count;
                    if (res < p2_result) p2_result = res;
                }
            }
        }
    }

    return .{ p1_result, p2_result };
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [7_000_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    const ListType = std.ArrayList([]const u8);
    var list = [2]ListType{ ListType.init(allocator), ListType.init(allocator) };
    defer for (list) |l| l.deinit();

    var idx: usize = 0;
    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        var row_iter = std.mem.tokenizeScalar(u8, row, ',');
        while (row_iter.next()) |elem| try list[idx].append(elem);
        idx += 1;
    }

    const p1, const p2 = try solver(allocator, .{ list[0].items, list[1].items });
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1, p2 });
}
