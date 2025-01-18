const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const prints = myf.printStr;
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const ProgT = i64;
const CT = i16;

const Result = struct { steps: u16, map: Map, oxygen_pos: Point };
const StatusCode = enum { Wall, Moved, MovedOxygen };
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

    pub fn run(self: *Self) StatusCode {
        while (true) {
            switch (self.set_pc_value_get_op()) {
                1 => self.set_value(3, self.get_value(1, 0) + self.get_value(2, 0)),
                2 => self.set_value(3, self.get_value(1, 0) * self.get_value(2, 0)),
                3 => self.set_value(1, self.input_value),
                4 => return @enumFromInt(self.get_value(1, 2)),
                5 => self.pc = if (self.get_value(1, 0) != 0) @intCast(self.get_value(2, 0)) else self.pc + 3,
                6 => self.pc = if (self.get_value(1, 0) == 0) @intCast(self.get_value(2, 0)) else self.pc + 3,
                7 => self.set_value(3, if (self.get_value(1, 0) < self.get_value(2, 0)) 1 else 0),
                8 => self.set_value(3, if (self.get_value(1, 0) == self.get_value(2, 0)) 1 else 0),
                9 => self.relative_base += self.get_value(1, 2),
                else => unreachable, // 99
            }
        }
    }
};

fn fogWalking(allocator: Allocator, registers: *const []ProgT) !Result {
    var queue = try Deque(struct { steps: u16, pos: Point, machine: Machine }).init(allocator);
    defer queue.deinit();
    try queue.pushBack(.{
        .steps = 0,
        .pos = Point.init(0, 0),
        .machine = .{ .registers = try allocator.dupe(ProgT, registers.*), .input_value = 0 },
    });

    var visited = Map.init(allocator);

    var oxygen_pos: Point = undefined;
    var min_steps: u16 = ~@as(u16, 0);
    while (queue.popFront()) |state| {
        defer allocator.free(state.machine.registers);
        if (visited.contains(state.pos)) continue;
        try visited.put(state.pos, {});

        for ([4]i64{ 1, 2, 3, 4 }) |i| {
            var new_machine = try state.machine.clone(allocator);
            new_machine.input_value = i;
            const result = new_machine.run();
            if (result == .Wall) {
                allocator.free(new_machine.registers);
                continue;
            }
            const dir = switch (i) {
                1 => Point.init(-1, 0),
                2 => Point.init(1, 0),
                3 => Point.init(0, -1),
                else => Point.init(0, 1),
            };

            const next_step = state.pos.add(dir);
            const new_step = state.steps + 1;
            if (result == .MovedOxygen) {
                if (new_step < min_steps) min_steps = new_step;
                oxygen_pos = next_step;
            }
            try queue.pushBack(.{ .machine = new_machine, .steps = new_step, .pos = next_step });
        }
    }
    return .{ .steps = min_steps, .map = visited, .oxygen_pos = oxygen_pos };
}

fn part2(allocator: Allocator, result: *const Result) !u16 {
    var queue = try Deque(struct { steps: u16, pos: Point }).init(allocator);
    defer queue.deinit();
    try queue.pushBack(.{ .steps = 0, .pos = result.oxygen_pos });

    var visited = Map.init(allocator);
    defer visited.deinit();

    var max_steps: u16 = 0;
    while (queue.popFront()) |state| {
        if ((try visited.getOrPutValue(state.pos, {})).found_existing) continue;
        max_steps = @max(max_steps, state.steps);

        for ([4]Point{ Point.init(-1, 0), Point.init(1, 0), Point.init(0, -1), Point.init(0, 1) }) |i| {
            const next_pos = state.pos.add(i);
            if (!result.map.contains(next_pos)) continue;
            try queue.pushBack(.{ .steps = state.steps + 1, .pos = next_pos });
        }
    }
    return max_steps;
}

fn printGrid(allocator: Allocator, result: *const Result, visited: ?*const Map) !void {
    var min_point = Point.init(0, 0);
    var max_point = Point.init(0, 0);
    for (result.map.keys()) |k| {
        min_point.row = @min(min_point.row, k.row);
        min_point.col = @min(min_point.col, k.col);
        max_point.row = @max(max_point.row, k.row);
        max_point.col = @max(max_point.col, k.col);
    }

    const rows: usize = @intCast(max_point.row - min_point.row);
    const cols: usize = @intCast(max_point.col - min_point.col);

    var matrix = try myf.initValueMatrix(allocator, rows + 3, cols + 3, @as(u8, '#'));
    defer myf.freeMatrix(allocator, matrix);
    for (result.map.keys()) |point| {
        const row, const col = point.sub(min_point).cast();
        matrix[row + 1][col + 1] = '.';
    }
    if (visited) |map| {
        for (map.keys()) |point| {
            const row, const col = point.sub(min_point).cast();
            matrix[row + 1][col + 1] = 'O';
        }
    }

    const row, const col = result.oxygen_pos.sub(min_point).cast();
    matrix[row + 1][col + 1] = '@';
    for (matrix) |r| prints(r);
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
    try registers.ensureTotalCapacityPrecise(4000);
    defer registers.deinit();

    var in_iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\r\n"), ',');
    while (in_iter.next()) |raw_value| registers.appendAssumeCapacity(try std.fmt.parseInt(ProgT, raw_value, 10));
    for (0..4000 - registers.items.len) |_| registers.appendAssumeCapacity(0);

    var p1_result = try fogWalking(allocator, &registers.items);
    defer p1_result.map.deinit();

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_result.steps, try part2(allocator, &p1_result) });
}
