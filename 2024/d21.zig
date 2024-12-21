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
};

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

const X = 16;
const A = 10;

const keypad = [_][3]u8{
    .{ 7, 8, 9 },
    .{ 4, 5, 6 },
    .{ 1, 2, 3 },
    .{ X, 0, A },
};

const rows: i8 = keypad.len;
const cols: i8 = keypad[0].len;

fn inBounds(p: Point) bool {
    return 0 <= p.row and p.row < rows and 0 <= p.col and p.col < cols and
        !p.eq(Point.init(3, 0));
}

const map = blk: {
    const buttons = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A };
    var btn_coord: [buttons.len]Point = undefined;
    for (buttons) |val| {
        for (0..keypad.len) |i| {
            for (0..keypad[0].len) |j| {
                if (val == keypad[i][j])
                    btn_coord[val] = Point.init(i, j);
            }
        }
    }

    break :blk btn_coord;
};

const start_row = 3;
const start_col = 2;
const start_A = Point.init(start_row, start_col);

test "example" {
    const allocator = std.testing.allocator;

    const input = @embedFile("in/d21t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        list.clearRetainingCapacity();
        var numeric: u16 = 0;
        for (row) |c| {
            const value = try std.fmt.charToDigit(c, 16);
            try list.append(value);
        }
        numeric = try std.fmt.parseInt(u16, row[0 .. row.len - 1], 10);
        printa(list.items);
        printa(numeric);
        break;
    }
    var path = try aStar(allocator, start_A, map[2]);
    defer path.deinit();
    printa(path.items);
}

const State = struct {
    count: CT,
    pos: Point,

    const Self = @This();

    fn cmp(_: void, a: Self, b: Self) std.math.Order {
        if (a.count < b.count) return .lt;
        if (a.count > b.count) return .gt;
        return .eq;
    }
};

fn aStar(allocator: Allocator, start: Point, goal: Point) !std.ArrayList(Point) {
    const MAX: CT = std.math.maxInt(CT);
    const NULL = Point.init(-1, -1);

    var g_score: [rows][cols]CT = undefined;
    var f_score: [rows][cols]CT = undefined;
    var edges: [rows][cols]Point = undefined;
    for (0..rows) |i| {
        for (0..cols) |j| {
            g_score[i][j] = MAX;
            f_score[i][j] = MAX;
            edges[i][j] = NULL;
        }
    }

    var path = std.ArrayList(Point).init(allocator);

    g_score[start.r()][start.c()] = 0;
    f_score[start.r()][start.c()] = start.manhattan(goal);

    var pqueue = PriorityQueue(State, void, State.cmp).init(allocator, undefined);
    defer pqueue.deinit();
    try pqueue.add(.{ .count = 0, .pos = start });

    while (pqueue.count() != 0) {
        const state = pqueue.remove();

        if (goal.eq(state.pos)) {
            var curr = state.pos;
            while (!edges[curr.r()][curr.c()].eq(NULL)) {
                try path.append(curr);
                curr = edges[curr.r()][curr.c()];
            }
            std.mem.reverse(Point, path.items);
            break;
        }

        for (myf.getNextPositions(state.pos.row, state.pos.col)) |next_coord| {
            const next_pos = Point.initA(next_coord);
            if (!inBounds(next_pos)) continue;

            const tmp_g_score = g_score[state.pos.r()][state.pos.c()] + 1;

            const next_row, const next_col = next_pos.cast();
            if (g_score[next_row][next_col] != MAX and tmp_g_score >= f_score[next_row][next_col]) {
                continue;
            }
            edges[next_row][next_col] = state.pos;

            g_score[next_row][next_col] = tmp_g_score;
            const new_f_score = tmp_g_score + next_pos.manhattan(goal);
            f_score[next_row][next_col] = new_f_score;
            try pqueue.add(.{ .count = new_f_score, .pos = next_pos });
        }
    }

    return path;
}
