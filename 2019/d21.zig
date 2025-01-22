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

const MachineInputIterator = struct {
    array: []const u8,
    index: usize = 0,
    end: []const u8,

    pub fn next(self: *MachineInputIterator) ?u8 {
        if (self.index >= self.array.len) {
            self.array = self.end;
            self.index = 0;
        }
        defer self.index += 1;
        return self.array[self.index];
    }
};
const Machine = struct {
    registers: std.ArrayList(ProgT),
    input_value: MachineInputIterator,
    relative_base: ProgT = 0,
    pc_value: ProgT = 0,
    pc: u32 = 0,

    const Self = @This();
    pub fn init(registers: std.ArrayList(ProgT), register_size: usize, input: []const u8, end: []const u8) !Machine {
        var regs = registers;
        for (0..register_size - registers.items.len) |_| try regs.append(0);
        return Machine{
            .registers = regs,
            .input_value = MachineInputIterator{ .array = input, .end = end },
        };
    }

    pub fn resetAndSet(self: *Self, input: []const u8) void {
        self.pc = 0;
        self.relative_base = 0;
        self.input_value.array = input;
        self.input_value.index = 0;
    }

    fn getFactor(param: u32) ProgT {
        return @intCast((std.math.powi(ProgT, 10, param) catch unreachable) * 10);
    }

    fn set_PcValue_get_op(self: *Self) ProgT {
        self.pc_value = self.registers.items[@intCast(self.pc)];
        return @mod(self.pc_value, 100);
    }

    fn getValue(self: *Self, param: u32, add_pc: u32) ProgT {
        const offset = self.pc + param;
        const item = switch (@mod(@divFloor(self.registers.items[self.pc], getFactor(param)), 10)) {
            0 => self.registers.items[offset],
            1 => offset,
            else => self.relative_base + self.registers.items[offset],
        };
        self.pc += add_pc;
        return self.registers.items[@intCast(item)];
    }

    fn setValue(self: *Self, param: u32, put_value: ProgT) void {
        const item = self.registers.items[self.pc + param];
        const index = switch (@mod(@divFloor(self.registers.items[self.pc], getFactor(param)), 10)) {
            0 => item,
            else => self.relative_base + item,
        };
        self.pc += param + 1;
        self.registers.items[@intCast(index)] = put_value;
    }

    pub fn run(self: *Self) ?ProgT {
        while (true) {
            switch (self.set_PcValue_get_op()) {
                1 => self.setValue(3, self.getValue(1, 0) + self.getValue(2, 0)),
                2 => self.setValue(3, self.getValue(1, 0) * self.getValue(2, 0)),
                3 => self.setValue(1, self.input_value.next().?),
                4 => return self.getValue(1, 2),
                5 => self.pc = if (self.getValue(1, 0) != 0) @intCast(self.getValue(2, 0)) else self.pc + 3,
                6 => self.pc = if (self.getValue(1, 0) == 0) @intCast(self.getValue(2, 0)) else self.pc + 3,
                7 => self.setValue(3, if (self.getValue(1, 0) < self.getValue(2, 0)) 1 else 0),
                8 => self.setValue(3, if (self.getValue(1, 0) == self.getValue(2, 0)) 1 else 0),
                9 => self.relative_base += self.getValue(1, 2),
                else => return null, // 99
            }
        }
    }
};

fn joinStrings(comptime strs: []const []const u8) []const u8 {
    comptime {
        const delim = "\n";
        var strings: []const u8 = "";
        for (strs, 0..) |s, i| {
            strings = strings ++ s;
            if (i != strs.len - 1) {
                strings = strings ++ delim;
            }
        }
        return strings;
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
    // End setup

    var registers = std.ArrayList(ProgT).init(allocator);
    defer registers.deinit();

    var in_iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\r\n"), ',');
    while (in_iter.next()) |raw_value| try registers.append(try std.fmt.parseInt(ProgT, raw_value, 10));

    const p1 = comptime joinStrings(&.{
        "NOT C J",
        "NOT A T",
        "OR T J",
        "AND D J",
    });
    const p2 = comptime joinStrings(&.{
        "NOT C J",
        "AND D J",
        "AND H J",
        "NOT B T",
        "AND D T",
        "OR T J",
        "NOT A T",
        "OR T J",
    });

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        try runMachine(&registers, p1, "WALK"),
        try runMachine(&registers, p2, "RUN"),
    });
}

fn runMachine(registers: *const std.ArrayList(ProgT), string: []const u8, comptime directive: []const u8) !i64 {
    var machine = try Machine.init(try registers.clone(), 2280, string, "\n" ++ directive ++ "\n");
    defer machine.registers.deinit();

    var result: i64 = 0;
    while (machine.run()) |res| {
        if (res > 255) {
            result = res;
            break;
        }
    }
    return result;
}
