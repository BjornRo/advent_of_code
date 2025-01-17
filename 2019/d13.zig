const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const CT = i16;
const ProgT = i64;

const Map = std.ArrayHashMap(Point, Tile, Point.HashCtx, true);

const Tile = enum { Empty, Wall, Block, Paddle, Ball };

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
    fn cast(self: Self) [2]u16 {
        return .{ @intCast(self.row), @intCast(self.col) };
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

const Machine = struct {
    registers: []ProgT,
    input_value: ProgT,
    relative_base: ProgT = 0,
    pc_value: ProgT = 0,
    pc: u32 = 0,
    output: ProgT = 0,

    const Self = @This();

    fn get_factor(param: u32) ProgT {
        return @intCast((std.math.powi(ProgT, 10, param) catch unreachable) * 10);
    }

    fn set_pc_value_get_op(self: *Self) ProgT {
        self.pc_value = self.registers[@intCast(self.pc)];
        return @mod(self.pc_value, 100);
    }

    pub fn get_value(self: *Self, param: u32, add_pc: u32) ProgT {
        const offset = self.pc + param;
        const item = switch (@mod(@divFloor(self.registers[self.pc], get_factor(param)), 10)) {
            0 => self.registers[offset], // position
            1 => offset, // immediate
            else => self.relative_base + self.registers[offset], // 2 => relative
        };
        self.pc += add_pc;
        return self.registers[@intCast(item)];
    }

    pub fn set_value(self: *Self, param: u32, put_value: ProgT) void {
        const item = self.registers[self.pc + param];
        const index = switch (@mod(@divFloor(self.registers[self.pc], get_factor(param)), 10)) {
            0 => item, // position
            else => self.relative_base + item, // relative
        };
        self.pc += param + 1;
        self.registers[@intCast(index)] = put_value;
    }

    pub fn run(self: *Self) ?CT {
        while (true) {
            switch (self.set_pc_value_get_op()) {
                1 => self.set_value(3, self.get_value(1, 0) + self.get_value(2, 0)),
                2 => self.set_value(3, self.get_value(1, 0) * self.get_value(2, 0)),
                3 => self.set_value(1, self.input_value),
                4 => return @intCast(self.get_value(1, 2)),
                5 => self.pc = if (self.get_value(1, 0) != 0) @intCast(self.get_value(2, 0)) else self.pc + 3,
                6 => self.pc = if (self.get_value(1, 0) == 0) @intCast(self.get_value(2, 0)) else self.pc + 3,
                7 => self.set_value(3, if (self.get_value(1, 0) < self.get_value(2, 0)) 1 else 0),
                8 => self.set_value(3, if (self.get_value(1, 0) == self.get_value(2, 0)) 1 else 0),
                9 => self.relative_base += self.get_value(1, 2),
                else => return null, // 99
            }
        }
    }
};

fn part1(allocator: Allocator, machine: *Machine) !struct { count: usize, map: Map } {
    var map = Map.init(allocator);
    var position = Point.init(0, 0);
    while (true) {
        if (machine.run()) |col| position.col = col else break;
        if (machine.run()) |row| position.row = row else break;
        if (machine.run()) |tile_id| try map.put(position, @enumFromInt(tile_id)) else break;
    }

    var count: usize = 0;
    for (map.values()) |v| {
        if (v == .Block) count += 1;
    }
    return .{ .count = count, .map = map };
}

fn part2(_: Allocator, machine: *Machine, map: *Map) !usize {
    machine.registers[0] = 2;

    _ = map;

    // while (true) {
    //     if (machine.run()) |col| position.col = col else break;
    //     if (machine.run()) |row| position.row = row else break;
    //     if (machine.run()) |tile_id| try map.put(position, @enumFromInt(tile_id)) else break;
    // }
    return 1;
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
    // var buffer: [35_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    var registers = std.ArrayList(ProgT).init(allocator);
    try registers.ensureTotalCapacityPrecise(10000);
    defer registers.deinit();

    var in_iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\r\n"), ',');
    while (in_iter.next()) |raw_value| registers.appendAssumeCapacity(try std.fmt.parseInt(ProgT, raw_value, 10));
    for (0..10000 - registers.items.len) |_| registers.appendAssumeCapacity(0);

    var machine = Machine{ .input_value = 0, .registers = registers.items };

    var result = try part1(allocator, &machine);
    defer result.map.deinit();
    print(result.count);

    _ = try part2(allocator, &machine, &result.map);

    // std.debug.print("{s}\n", .{input});
    // try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ 1, 2 });

}
