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

const CT = i16;

const Point = struct {
    row: CT,
    col: CT,

    const Self = @This();

    fn initA(arr: [2]CT) Self {
        return .{ .row = arr[0], .col = arr[1] };
    }
    fn init(row: anytype, col: anytype) Self {
        return .{ .row = @intCast(row), .col = @intCast(col) };
    }
    fn cast(self: Self) [2]u16 {
        return .{ @intCast(self.row), @intCast(self.col) };
    }
    fn eq(self: Self, o: Point) bool {
        return self.row == o.row and self.col == o.col;
    }
    fn eqA(self: Self, o: [2]CT) bool {
        return self.row == o[0] and self.col == o[1];
    }
    fn toArr(self: Self) [2]CT {
        return .{ self.row, self.col };
    }
    fn r(self: Self) u16 {
        return @intCast(self.row);
    }
    fn c(self: Self) u16 {
        return @intCast(self.col);
    }
    fn manhattan(self: Self, p: Self) CT {
        const res = myf.manhattan(self.toArr(), p.toArr());
        return @intCast(res);
    }
    fn addA(self: Self, arr: [2]CT) Point {
        return .{
            .row = self.row + arr[0],
            .col = self.col + arr[1],
        };
    }
    fn add(self: Self, p: Self) Point {
        return .{
            .row = self.row + p.row,
            .col = self.col + p.col,
        };
    }
    fn sub(self: Self, p: Self) Point {
        return .{
            .row = self.row - p.row,
            .col = self.col - p.col,
        };
    }
};

const X = 16; // just placeholder. Invalid case
const A = 10;

const rows: i8 = keypad.len;
const cols: i8 = keypad[0].len;

const keypad = blk: {
    const kp = [_][3]u8{
        .{ 7, 8, 9 },
        .{ 4, 5, 6 },
        .{ 1, 2, 3 },
        .{ X, 0, A },
    };
    const buttons = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A };
    var btn_coord: [buttons.len]Point = undefined;
    outer: for (buttons) |val| {
        for (0..kp.len) |i| {
            for (0..kp[0].len) |j| {
                if (val == kp[i][j]) {
                    btn_coord[val] = Point.init(i, j);
                    continue :outer;
                }
            }
        }
    }

    break :blk btn_coord;
};

fn dirpad(key: u8) Point {
    return switch (key) {
        '^' => Point.init(0, 1),
        'A' => Point.init(0, 2),
        '<' => Point.init(1, 0),
        'v' => Point.init(1, 1),
        '>' => Point.init(1, 2),
        else => unreachable,
    };
}

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
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input = @embedFile("in/d21.txt");
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

}

test "example" {
    const allocator = std.testing.allocator;

    const input = @embedFile("in/d21t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var sum: u64 = 0;

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        const numeric: u16 = try std.fmt.parseInt(u16, row[0 .. row.len - 1], 10);
    }
}

fn robots(level: u8, move: []const u8) !void {

    //
}
