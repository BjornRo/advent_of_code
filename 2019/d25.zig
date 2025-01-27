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
const Machine = struct {
    registers: std.ArrayList(ProgT),
    input_value: Deque(ProgT),
    relative_base: ProgT = 0,
    pc_value: ProgT = 0,
    pc: u32 = 0,

    const Self = @This();
    pub fn init(allocator: Allocator, registers: *const std.ArrayList(ProgT)) !Machine {
        return Machine{ .registers = try registers.clone(), .input_value = try Deque(ProgT).init(allocator) };
    }

    pub fn deinit(self: *Self) void {
        self.registers.deinit();
        self.input_value.deinit();
    }

    fn getFactor(param: u32) ProgT {
        return @intCast((std.math.powi(ProgT, 10, param) catch unreachable) * 10);
    }

    fn setPcValueGetOp(self: *Self) ProgT {
        self.pc_value = self.getReg(self.pc);
        return @mod(self.pc_value, 100);
    }

    fn setReg(self: *Self, index: anytype, value: ProgT) void {
        const i: u16 = @intCast(index);
        if (i >= self.registers.items.len)
            self.registers.appendNTimes(0, i - self.registers.items.len + 1) catch unreachable;
        self.registers.items[i] = value;
    }

    fn getReg(self: *Self, index: anytype) ProgT {
        const i: u16 = @intCast(index);
        if (i >= self.registers.items.len)
            self.registers.appendNTimes(0, i - self.registers.items.len + 1) catch unreachable;
        return self.registers.items[i];
    }

    fn getValue(self: *Self, param: u32, add_pc: u32) ProgT {
        const offset = self.pc + param;
        const item = switch (@mod(@divFloor(self.getReg(self.pc), getFactor(param)), 10)) {
            0 => self.getReg(offset),
            1 => offset,
            else => self.relative_base + self.getReg(offset),
        };
        self.pc += add_pc;
        return self.getReg(item);
    }

    fn setValue(self: *Self, param: u32, put_value: ProgT) void {
        const item = self.getReg(self.pc + param);
        const index = switch (@mod(@divFloor(self.getReg(self.pc), getFactor(param)), 10)) {
            0 => item,
            else => self.relative_base + item,
        };
        self.pc += param + 1;
        self.setReg(index, put_value);
    }

    pub fn run(self: *Self) ?ProgT {
        while (true) {
            switch (self.setPcValueGetOp()) {
                1 => self.setValue(3, self.getValue(1, 0) + self.getValue(2, 0)),
                2 => self.setValue(3, self.getValue(1, 0) * self.getValue(2, 0)),
                3 => self.setValue(1, self.input_value.popFront() orelse 0),
                4 => return self.getValue(1, 2),
                5 => self.pc = if (self.getValue(1, 0) != 0) @intCast(self.getValue(2, 0)) else self.pc + 3,
                6 => self.pc = if (self.getValue(1, 0) == 0) @intCast(self.getValue(2, 0)) else self.pc + 3,
                7 => self.setValue(3, if (self.getValue(1, 0) < self.getValue(2, 0)) 1 else 0),
                8 => self.setValue(3, if (self.getValue(1, 0) == self.getValue(2, 0)) 1 else 0),
                9 => self.relative_base += self.getValue(1, 2),
                else => {}, // 99
            }
        }
        return null;
    }
    pub fn output(self: *Self, list: *std.ArrayList(u8)) !void {
        while (self.run()) |item| {
            try list.append(@intCast(item));
            if (std.mem.endsWith(u8, list.items, "Command?")) break;
        }
    }
};

fn runMachine(allocator: Allocator, registers: *const std.ArrayList(ProgT)) !void {
    var machine = try Machine.init(allocator, registers);
    var list = std.ArrayList(u8).init(allocator);
    defer inline for (.{ &list, &machine }) |x| x.deinit();

    var stdin = std.io.getStdIn().reader();

    while (true) {
        list.clearRetainingCapacity();
        try machine.output(&list);
        prints(list.items);

        list.clearRetainingCapacity();
        try stdin.readUntilDelimiterArrayList(&list, '\n', 64);

        for (std.mem.trimRight(u8, list.items, "\r\n")) |c| try machine.input_value.pushBack(c);
        try machine.input_value.pushBack('\n');
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

    try runMachine(allocator, &registers);
}
