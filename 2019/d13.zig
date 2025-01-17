const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const prints = myf.printStr;
const Allocator = std.mem.Allocator;

const ProgT = i64;
const CT = i16;

const Tile = enum { Empty, Wall, Block, Paddle, Ball };

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
    fn cast(self: Self) [2]u16 {
        return .{ @intCast(self.row), @intCast(self.col) };
    }
};

const Machine = struct {
    registers: []ProgT,
    input_value: ProgT,
    relative_base: ProgT = 0,
    pc_value: ProgT = 0,
    pc: u32 = 0,

    const Self = @This();

    fn get_factor(param: u32) ProgT {
        return @intCast((std.math.powi(ProgT, 10, param) catch unreachable) * 10);
    }

    fn set_pc_value_get_op(self: *Self) ProgT {
        self.pc_value = self.registers[@intCast(self.pc)];
        return @mod(self.pc_value, 100);
    }

    fn get_value(self: *Self, param: u32, add_pc: u32) ProgT {
        const offset = self.pc + param;
        const item = switch (@mod(@divFloor(self.registers[self.pc], get_factor(param)), 10)) {
            0 => self.registers[offset], // position
            1 => offset, // immediate
            else => self.relative_base + self.registers[offset], // 2 => relative
        };
        self.pc += add_pc;
        return self.registers[@intCast(item)];
    }

    fn set_value(self: *Self, param: u32, put_value: ProgT) void {
        const item = self.registers[self.pc + param];
        const index = switch (@mod(@divFloor(self.registers[self.pc], get_factor(param)), 10)) {
            0 => item, // position
            else => self.relative_base + item, // relative
        };
        self.pc += param + 1;
        self.registers[@intCast(index)] = put_value;
    }

    pub fn runTriplet(self: *Self) ?struct { point: Point, tile: ProgT } {
        const col = if (self.run()) |col| col else return null;
        const row = if (self.run()) |row| row else return null;
        const tile = if (self.run()) |tile| tile else return null;
        return .{ .point = Point.init(@intCast(row), @intCast(col)), .tile = tile };
    }

    pub fn run(self: *Self) ?ProgT {
        while (true) {
            switch (self.set_pc_value_get_op()) {
                1 => self.set_value(3, self.get_value(1, 0) + self.get_value(2, 0)),
                2 => self.set_value(3, self.get_value(1, 0) * self.get_value(2, 0)),
                3 => self.set_value(1, self.input_value),
                4 => return self.get_value(1, 2),
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

fn breakout(allocator: Allocator, machine: *Machine, print_game: bool) ![2]usize {
    machine.registers[0] = 2;

    var matrix: [][]u8 = undefined;
    var matrix_init = false;
    defer if (matrix_init) myf.freeMatrix(allocator, matrix);

    var started = false;
    var paddle_pos: Point = undefined;

    var p1_result: usize = 0;
    var p2_result: usize = 0;
    while (machine.runTriplet()) |result| {
        if (print_game and !matrix_init) {
            matrix = try myf.initValueMatrix(allocator, 23, 37, @as(u8, ' '));
            matrix_init = true;
        }
        if (Point.init(0, -1).eq(result.point)) {
            started = true;
            if (result.tile > p2_result) p2_result = @intCast(result.tile);
        } else {
            const row, const col = result.point.cast();
            const tile_type: Tile = @enumFromInt(result.tile);
            switch (tile_type) {
                .Block => {
                    if (!started) p1_result += 1;
                },
                .Paddle => paddle_pos = result.point,
                .Ball => machine.input_value = if (paddle_pos.col < col) 1 else if (paddle_pos.col > col) -1 else 0,
                else => {},
            }

            if (print_game) {
                matrix[row][col] = switch (tile_type) {
                    .Ball => 'O',
                    .Block => 'X',
                    .Empty => ' ',
                    .Paddle => '=',
                    .Wall => '#',
                };
            }
        }
        if (print_game and started and result.tile != 0) {
            for (matrix) |row| prints(row);
            myf.slowDown(5);
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
    var buffer: [90_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

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

    const p1, const p2 = try breakout(allocator, &machine, false);
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1, p2 });
}
