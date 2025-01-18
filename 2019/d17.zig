const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const printd = std.debug.print;
const print = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const ProgT = i64;
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
    fn sub(self: Self, o: Point) Point {
        return Self.init(self.row - o.row, self.col - o.col);
    }
    fn eq(self: Self, o: Point) bool {
        return self.row == o.row and self.col == o.col;
    }
    fn cast(self: Self) [2]u16 {
        return .{ @intCast(self.row), @intCast(self.col) };
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

    const Self = @This();

    pub fn clone(self: Self, allocator: Allocator) !Machine {
        return Machine{
            .registers = try allocator.dupe(ProgT, self.registers),
            .input_value = self.input_value,
            .pc_value = self.pc_value,
            .pc = self.pc,
        };
    }

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
            0 => self.registers[offset],
            1 => offset,
            else => self.relative_base + self.registers[offset],
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

    pub fn run(self: *Self) ?u8 {
        while (true) {
            switch (self.set_pc_value_get_op()) {
                1 => self.set_value(3, self.get_value(1, 0) + self.get_value(2, 0)),
                2 => self.set_value(3, self.get_value(1, 0) * self.get_value(2, 0)),
                3 => self.set_value(1, self.input_value),
                4 => return @intCast(@as(i8, @truncate(self.get_value(1, 2)))),
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

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d17.txt");

    var registers = std.ArrayList(ProgT).init(allocator);
    try registers.ensureTotalCapacityPrecise(5500);
    defer registers.deinit();

    var in_iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\r\n"), ',');
    while (in_iter.next()) |raw_value| registers.appendAssumeCapacity(try std.fmt.parseInt(ProgT, raw_value, 10));
    for (0..5500 - registers.items.len) |_| registers.appendAssumeCapacity(0);

    try part1(allocator, registers.items);
}

fn part1(allocator: Allocator, registers: []ProgT) !void {
    var linear_matrix = std.ArrayList(u8).init(allocator);
    defer linear_matrix.deinit();

    var machine: Machine = .{ .registers = registers, .input_value = 0 };

    while (machine.run()) |value| try linear_matrix.append(value);
    const line_len_newline = std.mem.indexOfScalar(u8, linear_matrix.items, '\n').? + 1;
    const lines = (linear_matrix.items.len - 1) / line_len_newline;

    const matrix = try allocator.alloc([]u8, lines);
    defer allocator.free(matrix);

    var lm_it = std.mem.tokenizeScalar(u8, linear_matrix.items, '\n');
    {
        var i: u8 = 0;
        while (lm_it.next()) |row| {
            matrix[i] = @constCast(row);
            i += 1;
        }
    }

    // 6371 too high
    var sum: usize = 0;
    for (1..matrix.len - 1) |i| {
        for (1..matrix[0].len - 1) |j| {
            if (matrix[i][j] != '#') continue;
            const ii: i8 = @intCast(i);
            const jj: i8 = @intCast(j);
            var count: u8 = 0;
            for (myf.getNextPositions(ii, jj)) |pos| {
                const row, const col = pos;
                if (matrix[@intCast(row)][@intCast(col)] == '#') {
                    count += 1;
                }
            }
            if (count == 4) {
                matrix[i][j] = 'O';
                sum += i * j;
            }
        }
    }

    for (matrix) |row| prints(row);
    print(sum);
}
