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

const Point = struct {
    row: CT,
    col: CT,

    const Self = @This();
    fn init(row: CT, col: CT) Self {
        return .{ .row = row, .col = col };
    }
    fn initA(arr: [2]CT) Self {
        return .{ .row = arr[0], .col = arr[1] };
    }
    fn add(self: Self, o: Point) Point {
        return Self.init(self.row + o.row, self.col + o.col);
    }
    fn mul(self: Point, other: Point) Point {
        return Point.init(
            self.row * other.row - self.col * other.col,
            self.row * other.col + self.col * other.row,
        );
    }
    fn cast(self: Self) [2]u16 {
        return .{ @intCast(self.row), @intCast(self.col) };
    }
};

const CharIterator = struct {
    str: []const u16,
    index: usize = 0,

    fn next(self: *CharIterator) ?u16 {
        if (self.index >= self.str.len) return null;
        defer self.index += 1;
        return self.str[self.index];
    }
};

const Machine = struct {
    registers: std.ArrayList(ProgT),
    input_value: ?CharIterator = null,
    relative_base: ProgT = 0,
    pc_value: ProgT = 0,
    pc: u32 = 0,

    const Self = @This();

    pub fn init(registers: std.ArrayList(ProgT), register_size: usize) !Machine {
        var regs = registers;
        for (0..register_size - registers.items.len) |_| try regs.append(0);
        return Machine{ .registers = regs };
    }

    fn get_factor(param: u32) ProgT {
        return @intCast((std.math.powi(ProgT, 10, param) catch unreachable) * 10);
    }

    fn set_pc_value_get_op(self: *Self) ProgT {
        self.pc_value = self.registers.items[@intCast(self.pc)];
        return @mod(self.pc_value, 100);
    }

    fn get_value(self: *Self, param: u32, add_pc: u32) ProgT {
        const offset = self.pc + param;
        const item = switch (@mod(@divFloor(self.registers.items[self.pc], get_factor(param)), 10)) {
            0 => self.registers.items[offset],
            1 => offset,
            else => self.relative_base + self.registers.items[offset],
        };
        self.pc += add_pc;
        return self.registers.items[@intCast(item)];
    }

    fn set_value(self: *Self, param: u32, put_value: ProgT) void {
        const item = self.registers.items[self.pc + param];
        const index = switch (@mod(@divFloor(self.registers.items[self.pc], get_factor(param)), 10)) {
            0 => item,
            else => self.relative_base + item,
        };
        self.pc += param + 1;
        self.registers.items[@intCast(index)] = put_value;
    }

    pub fn run(self: *Self) ?u8 {
        while (true) {
            switch (self.set_pc_value_get_op()) {
                1 => self.set_value(3, self.get_value(1, 0) + self.get_value(2, 0)),
                2 => self.set_value(3, self.get_value(1, 0) * self.get_value(2, 0)),
                3 => self.set_value(1, self.input_value.?.next().?),
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

    const input = @embedFile("in/d19.txt");

    var registers = std.ArrayList(ProgT).init(allocator);
    defer registers.deinit();

    var in_iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\r\n"), ',');
    while (in_iter.next()) |raw_value| try registers.append(try std.fmt.parseInt(ProgT, raw_value, 10));

    try part1(allocator, &registers);
}

fn part1(allocator: Allocator, registers: *const std.ArrayList(ProgT)) !void {
    var buffer = myf.FixedBuffer(u16, 2).init();
    // var output = std.ArrayList(u8).init(allocator);
    // defer output.deinit();

    var matrix = try myf.initValueMatrix(allocator, 100, 100, @as(u8, 0));
    defer myf.freeMatrix(allocator, matrix);

    var count: u32 = 0;
    for (0..100) |i| {
        var row_count: u32 = 0;
        for (0..100) |j| {
            buffer.len = 0;
            var machine = try Machine.init(try registers.*.clone(), 1000);
            defer machine.registers.deinit();
            buffer.appendAssumeCapacity(@intCast(j));
            buffer.appendAssumeCapacity(@intCast(i));
            machine.input_value = CharIterator{ .str = buffer.getSlice() };
            if (machine.run()) |result| {
                if (result == 1) {
                    matrix[i][j] = '#';
                    row_count += 1;
                } else matrix[i][j] = '.';
            }
        }
        std.debug.print("i: {d}, count: {d}\n", .{ i, row_count });
        count += row_count;
    }
    for (matrix) |row| {
        prints(row);
    }
    // print(count);
}

// fn part1(allocator: Allocator, registers: *const std.ArrayList(ProgT)) !void {
//     var machine = try Machine.init(try registers.*.clone(), 2000);
//     var linear_matrix = std.ArrayList(u8).init(allocator);
//     defer inline for (.{ machine.registers, linear_matrix }) |x| x.deinit();

//     while (machine.run()) |value| try linear_matrix.append(@intCast(@as(i8, @truncate(value))));

//     var matrix = blk: {
//         const line_len_newline = std.mem.indexOfScalar(u8, linear_matrix.items, '\n').? + 1;
//         const lines = (linear_matrix.items.len - 1) / line_len_newline;
//         var matrix = try myf.initValueMatrix(allocator, lines + 2, line_len_newline + 1, @as(u8, '.'));
//         var lm_it = std.mem.tokenizeScalar(u8, linear_matrix.items, '\n');
//         var i: u8 = 1;
//         while (lm_it.next()) |row| {
//             for (row, 1..) |e, j| matrix[i][j] = e;
//             i += 1;
//         }
//         break :blk matrix;
//     };

//     var sum: usize = 0;
//     for (1..matrix.len - 1) |i| {
//         for (1..matrix[0].len - 1) |j| {
//             if (matrix[i][j] != '#') continue;
//             const ii: i8 = @intCast(i);
//             const jj: i8 = @intCast(j);
//             var count: u8 = 0;
//             for (myf.getNextPositions(ii, jj)) |pos| {
//                 const row, const col = pos;
//                 if (matrix[@intCast(row)][@intCast(col)] == '#') count += 1;
//             }
//             if (count == 4) {
//                 matrix[i][j] = 'O';
//                 sum += (i - 1) * (j - 1);
//             }
//         }
//     }
//     return .{ .p1_result = sum, .matrix = matrix };
// }
