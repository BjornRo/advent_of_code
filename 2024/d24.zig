const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;
const endian = @import("builtin").cpu.arch.endian();

fn arrToInt(arr: []const u8) u24 {
    const value: u24 = @bitCast([_]u8{ arr[0], arr[1], arr[2] });
    return if (.big == endian) value else @byteSwap(value);
}

fn intToArr(int: u24) [3]u8 {
    const value = if (.big == endian) int else @byteSwap(int);
    return @bitCast(value);
}

test "casting" {
    const str0 = "abx";
    const int0 = arrToInt(str0);
    try expect(std.mem.eql(u8, str0, &intToArr(int0)));
    const str1 = "z01";
    const int1 = arrToInt(str1);
    try expect(std.mem.eql(u8, str1, &intToArr(int1)));
    const str2 = "z00";
    const int2 = arrToInt(str2);
    try expect(std.mem.eql(u8, str2, &intToArr(int2)));
    const str3 = "00z";
    const int3 = arrToInt(str3);
    try expect(std.mem.eql(u8, str3, &intToArr(int3)));
    try expect(int0 != int1 and int0 != int2 and int0 != int3 and int1 != int2 and int1 != int3);
}

const InSignal = packed struct {
    id: u24,
    value: bool,
};

const Op = enum {
    XOR,
    AND,
    OR,

    const Self = @This();

    fn fromChar(char: u8) Self {
        return switch (char) {
            'X' => .XOR,
            'O' => .OR,
            'A' => .AND,
            else => unreachable,
        };
    }
};

const Gate = struct {
    left: u24,
    left_in: ?bool,
    right: u24,
    right_in: ?bool,
    op: Op,

    const Self = @This();
    fn out(self: Self) ?bool {
        if (self.left_in == null or self.right_in == null)
            return null;
        return switch (self.op) {
            .XOR => self.left_in.? != self.right_in.?,
            .AND => self.left_in.? and self.right_in.?,
            .OR => self.left_in.? or self.right_in.?,
        };
    }
};

const Grid = std.AutoHashMap(u24, Gate);
const InSignals = std.AutoHashMap(u24, bool);

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
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
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    // std.debug.print("{s}\n", .{input});
}

// 43109482179994 too low
test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d24.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var in_iter = std.mem.tokenizeSequence(u8, input, double_delim);
    const raw_signals = in_iter.next().?;
    const raw_grid = in_iter.next().?;

    var signals = InSignals.init(allocator);
    defer signals.deinit();
    var grid = Grid.init(allocator);
    defer grid.deinit();

    var zee = std.ArrayList(u24).init(allocator);
    defer zee.deinit();

    var signal_it = std.mem.tokenizeSequence(u8, raw_signals, input_attributes.delim);
    while (signal_it.next()) |row| try signals.put(arrToInt(row[0..3]), row[row.len - 1] == '1');
    std.mem.sort(u24, zee.items, {}, std.sort.desc(u24));

    var grid_it = std.mem.tokenizeSequence(u8, raw_grid, input_attributes.delim);
    while (grid_it.next()) |row| {
        var row_iter = std.mem.tokenizeScalar(u8, row, ' ');
        const left = arrToInt(row_iter.next().?);
        const op = Op.fromChar(row_iter.next().?[0]);
        const right = arrToInt(row_iter.next().?);
        _ = row_iter.next().?; // Arrow
        const out_str = row_iter.next().?;
        const out = arrToInt(out_str);
        try grid.put(out, .{
            .left = left,
            .left_in = signals.get(left),
            .right = right,
            .right_in = signals.get(right),
            .op = op,
        });
        if (out_str[0] == 'z') try zee.append(out);
    }

    const p1_number = try part1(allocator, grid, zee.items);
    printa(p1_number);
}

fn part1(allocator: Allocator, grid_: Grid, zee: []const u24) !u64 {
    var grid = try grid_.clone();
    defer grid.deinit();

    var queue = try Deque(*Gate).initCapacity(allocator, grid.count());
    defer queue.deinit();

    var grid_iter = grid.valueIterator();
    while (grid_iter.next()) |g| try queue.pushBack(g);

    while (queue.len() != 0) {
        const gate = queue.popFront().?;

        if (gate.*.left_in == null) {
            if (grid.get(gate.*.left).?.out()) |res| {
                gate.*.left_in = res;
            }
        }
        if (gate.*.right_in == null) {
            if (grid.get(gate.*.right).?.out()) |res| {
                gate.*.right_in = res;
            }
        }

        if (gate.*.left_in == null or gate.*.right_in == null)
            try queue.pushBack(gate);
    }

    var number: u64 = 0;
    for (zee.items) |z| {
        const val: u64 = if (grid.get(z).?.out().?) 1 else 0;
        number = number * 2 + val;
    }
    return number;
}
