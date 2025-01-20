const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const ProgT = i64;
const MachineInputIterator = struct {
    array: []const u16,
    index: usize = 0,

    pub fn next(self: *MachineInputIterator) ?u16 {
        if (self.index >= self.array.len) return null;
        defer self.index += 1;
        return self.array[self.index];
    }
};

const Machine = struct {
    registers: std.ArrayList(ProgT),
    input_value: ?MachineInputIterator = null,
    relative_base: ProgT = 0,
    pc_value: ProgT = 0,
    pc: u32 = 0,

    const Self = @This();

    pub fn init(registers: std.ArrayList(ProgT), register_size: usize, input: []const u16) !Machine {
        var regs = registers;
        for (0..register_size - registers.items.len) |_| try regs.append(0);
        return Machine{ .registers = regs, .input_value = MachineInputIterator{ .array = input } };
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

fn runMachine(registers: *const std.ArrayList(ProgT), i: usize, j: usize) !bool {
    var buffer = myf.FixedBuffer(u16, 2).init();
    buffer.appendAssumeCapacity(@intCast(i));
    buffer.appendAssumeCapacity(@intCast(j));
    var machine = try Machine.init(try registers.*.clone(), 1000, buffer.getSlice());
    defer machine.registers.deinit();
    return machine.run().? == 1;
}

fn part1(allocator: Allocator, registers: *const std.ArrayList(ProgT)) !u16 {
    var matrix = try myf.initValueMatrix(allocator, 50, 50, @as(u8, 0));
    defer myf.freeMatrix(allocator, matrix);

    var count: u16 = 0;
    for (0..50) |i| for (0..50) |j| {
        if (try runMachine(registers, i, j)) {
            matrix[i][j] = '#';
            count += 1;
        } else matrix[i][j] = '.';
    };
    for (matrix) |row| prints(row);
    return count;
}

fn part2(registers: *const std.ArrayList(ProgT)) !usize {
    var i: usize = 100;
    var j: usize = 150;
    while (true) : (i += 1) while (true) : (j += 1) {
        if (try runMachine(registers, i + 99, j)) {
            if (try runMachine(registers, i, j + 99)) return i * 10_000 + j;
            break;
        }
    };
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
    // End setup

    var registers = std.ArrayList(ProgT).init(allocator);
    defer registers.deinit();

    var in_iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\r\n"), ',');
    while (in_iter.next()) |raw_value| try registers.append(try std.fmt.parseInt(ProgT, raw_value, 10));

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ try part1(allocator, &registers), try part2(&registers) });
}
