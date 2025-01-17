const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const MapAxis = std.HashMap([4]CT, usize, HashCtx, 90);
const HashCtx = struct {
    pub fn hash(_: @This(), key: [4]CT) u64 {
        const arr: [8]u8 = @bitCast(key);
        return std.hash.XxHash64.hash(0, &arr);
    }
    pub fn eql(_: @This(), a: [4]CT, b: [4]CT) bool {
        return std.mem.eql(CT, &a, &b);
    }
};
const CT = i16;
const Point = struct {
    x: CT,
    y: CT,
    z: CT,

    const Self = @This();
    fn init(x: CT, y: CT, z: CT) Self {
        return .{ .x = x, .y = y, .z = z };
    }
    fn update(self: *Self, o: Point) void {
        self.x += o.x;
        self.y += o.y;
        self.z += o.z;
    }
};

const Moon = struct {
    pos: Point,
    vel: Point = Point.init(0, 0, 0),

    const Self = @This();
    fn gravity(self: *Self, o: *Moon) void {
        const t: CT = 1;
        const f: CT = 0;
        const dx = if (self.pos.x < o.pos.x) t else f - if (self.pos.x > o.pos.x) t else f;
        const dy = if (self.pos.y < o.pos.y) t else f - if (self.pos.y > o.pos.y) t else f;
        const dz = if (self.pos.z < o.pos.z) t else f - if (self.pos.z > o.pos.z) t else f;

        self.vel.x += dx;
        o.vel.x -= dx;
        self.vel.y += dy;
        o.vel.y -= dy;
        self.vel.z += dz;
        o.vel.z -= dz;
    }
    fn energy(self: *Self) usize {
        var total_energy: usize = 1;
        inline for (.{ self.pos, self.vel }) |p|
            total_energy *= @abs(p.x) + @abs(p.y) + @abs(p.z);
        return total_energy;
    }
};

fn parseLine(line: []const u8) !Point {
    var buf = myf.FixedBuffer(CT, 3).init();
    var line_iter = std.mem.tokenizeSequence(u8, line[1 .. line.len - 1], ", ");
    while (line_iter.next()) |sub| {
        var eq_it = std.mem.splitBackwardsScalar(u8, sub, '=');
        try buf.append(try std.fmt.parseInt(CT, eq_it.next().?, 10));
    }
    return Point.init(try buf.get(0), try buf.get(1), try buf.get(2));
}

fn solver(allocator: Allocator, moons: *[]Moon) ![2]u64 {
    var velocity_cycles = MapAxis.init(allocator);
    try velocity_cycles.put(.{ 0, 0, 0, 0 }, 0);
    defer velocity_cycles.deinit();
    var cycles: [3]?u64 = .{null} ** 3;
    var buf_velX: [4]CT = undefined;
    var buf_velY: [4]CT = undefined;
    var buf_velZ: [4]CT = undefined;

    var p1_res: u64 = 0;
    var step: usize = 0;
    while (true) {
        defer step += 1;
        if (step != 0) {
            if (step == 1000) {
                for (moons.*) |*m| p1_res += m.energy();
            }
            for (moons.*, 0..) |m, midx| {
                buf_velX[midx] = m.vel.x;
                buf_velY[midx] = m.vel.y;
                buf_velZ[midx] = m.vel.z;
            }

            for ([3][4]CT{ buf_velX, buf_velY, buf_velZ }, 0..) |buf, idx| {
                const result = try velocity_cycles.getOrPut(buf);
                if (result.found_existing) {
                    if (result.value_ptr.* == 0 and cycles[idx] == null) {
                        cycles[idx] = @intCast(step);
                        for (cycles) |v| {
                            if (v == null) break;
                        } else return .{
                            p1_res,
                            myf.lcm(myf.lcm(cycles[0].?, cycles[1].?), cycles[2].?) * 2,
                        };
                    }
                } else result.value_ptr.* = step;
            }
        }

        for (0..moons.len - 1) |i| for (i + 1..moons.len) |j| moons.*[i].gravity(&moons.*[j]);
        for (moons.*) |*m| m.pos.update(m.vel);
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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    var list = std.ArrayList(Moon).init(allocator);
    defer list.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |line| try list.append(.{ .pos = try parseLine(line) });

    const p1, const p2 = try solver(allocator, &list.items);
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1, p2 });
}
