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
    fn deltaP(self: Self, p: Self) Point {
        return .{
            .row = self.row - p.row,
            .col = self.col - p.col,
        };
    }
    fn delta(self: Self, p: Self) [2]CT {
        return .{
            self.row - p.row,
            self.col - p.col,
        };
    }
};

const HashCtx = struct {
    pub fn hash(_: @This(), key: Point) u32 {
        return @bitCast([2]CT{ key.row, key.col });
    }
    pub fn eql(_: @This(), a: Point, b: Point, _: usize) bool {
        return a.eq(b);
    }
};
const Edges = std.ArrayHashMap(Point, Point, HashCtx, true);

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

const N = Point.init(-1, -1);
const Ad = Point.init(0, 0);
const U = Point.init(-1, 0);
const D = Point.init(1, 0);
const L = Point.init(0, -1);
const R = Point.init(0, 1);

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

const DirPad = enum { LEFT, RIGHT, UP, DOWN, A };

const start_row = 3;
const start_col = 2;

test "example" {
    const allocator = std.testing.allocator;

    const input = @embedFile("in/d21t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    // const keypad = [_][3]u8{
    //     .{ 7, 8, 9 },
    //     .{ 4, 5, 6 },
    //     .{ 1, 2, 3 },
    //     .{ X, 0, A },
    // };
    // const dirpad = [_][3]u8{
    //     .{ N, U, Ad },
    //     .{ L, D, R },
    // };
    var robot_cost_map = std.AutoArrayHashMap([2]DirPad, u8).init(allocator);
    defer robot_cost_map.deinit();

    var robot_cost_map_raw = std.AutoArrayHashMap([2]DirPad, u8).init(allocator);
    defer robot_cost_map_raw.deinit();
    try robot_cost_map_raw.put(.{ .LEFT, .RIGHT }, 2);
    try robot_cost_map_raw.put(.{ .LEFT, .DOWN }, 1);
    try robot_cost_map_raw.put(.{ .LEFT, .UP }, 2);
    try robot_cost_map_raw.put(.{ .LEFT, .A }, 3);
    try robot_cost_map_raw.put(.{ .RIGHT, .DOWN }, 1);
    try robot_cost_map_raw.put(.{ .RIGHT, .UP }, 2);
    try robot_cost_map_raw.put(.{ .RIGHT, .LEFT }, 2);
    try robot_cost_map_raw.put(.{ .RIGHT, .A }, 1);
    try robot_cost_map_raw.put(.{ .UP, .A }, 1);
    try robot_cost_map_raw.put(.{ .UP, .DOWN }, 1);
    try robot_cost_map_raw.put(.{ .DOWN, .A }, 2);
    try robot_cost_map_raw.put(.{ .LEFT, .LEFT }, 0);
    try robot_cost_map_raw.put(.{ .RIGHT, .RIGHT }, 0);
    try robot_cost_map_raw.put(.{ .UP, .UP }, 0);
    try robot_cost_map_raw.put(.{ .A, .A }, 0);
    try robot_cost_map_raw.put(.{ .DOWN, .DOWN }, 0);
    for (robot_cost_map_raw.keys(), robot_cost_map_raw.values()) |key, value| {
        const left, const right = key;
        try robot_cost_map.put(key, value);
        try robot_cost_map.put(.{ right, left }, value);
    }

    var robot_kp_map = std.AutoArrayHashMap([2]DirPad, []const DirPad).init(allocator);
    defer robot_kp_map.deinit();

    try robot_kp_map.put(.{ .A, .LEFT }, &[_]DirPad{ DirPad.DOWN, DirPad.LEFT, DirPad.LEFT });
    try robot_kp_map.put(.{ .A, .UP }, &[_]DirPad{DirPad.LEFT});
    try robot_kp_map.put(.{ .A, .DOWN }, &[_]DirPad{ DirPad.DOWN, DirPad.LEFT });
    try robot_kp_map.put(.{ .A, .RIGHT }, &[_]DirPad{DirPad.DOWN});
    try robot_kp_map.put(.{ .A, .A }, &[_]DirPad{});
    try robot_kp_map.put(.{ .LEFT, .A }, &[_]DirPad{ DirPad.RIGHT, DirPad.RIGHT, DirPad.UP });
    try robot_kp_map.put(.{ .LEFT, .UP }, &[_]DirPad{ DirPad.RIGHT, DirPad.UP });
    try robot_kp_map.put(.{ .LEFT, .DOWN }, &[_]DirPad{DirPad.RIGHT});
    try robot_kp_map.put(.{ .LEFT, .RIGHT }, &[_]DirPad{ DirPad.RIGHT, DirPad.RIGHT });
    try robot_kp_map.put(.{ .LEFT, .LEFT }, &[_]DirPad{});
    try robot_kp_map.put(.{ .UP, .LEFT }, &[_]DirPad{ DirPad.DOWN, DirPad.LEFT });
    try robot_kp_map.put(.{ .UP, .A }, &[_]DirPad{DirPad.RIGHT});
    try robot_kp_map.put(.{ .UP, .RIGHT }, &[_]DirPad{ DirPad.DOWN, DirPad.RIGHT });
    try robot_kp_map.put(.{ .UP, .DOWN }, &[_]DirPad{DirPad.DOWN});
    try robot_kp_map.put(.{ .UP, .UP }, &[_]DirPad{});
    try robot_kp_map.put(.{ .RIGHT, .A }, &[_]DirPad{DirPad.UP});
    try robot_kp_map.put(.{ .RIGHT, .DOWN }, &[_]DirPad{DirPad.LEFT});
    try robot_kp_map.put(.{ .RIGHT, .UP }, &[_]DirPad{ DirPad.LEFT, DirPad.UP });
    try robot_kp_map.put(.{ .RIGHT, .LEFT }, &[_]DirPad{ DirPad.LEFT, DirPad.LEFT });
    try robot_kp_map.put(.{ .RIGHT, .RIGHT }, &[_]DirPad{});
    try robot_kp_map.put(.{ .DOWN, .A }, &[_]DirPad{ DirPad.RIGHT, DirPad.UP });
    try robot_kp_map.put(.{ .DOWN, .RIGHT }, &[_]DirPad{DirPad.RIGHT});
    try robot_kp_map.put(.{ .DOWN, .UP }, &[_]DirPad{DirPad.UP});
    try robot_kp_map.put(.{ .DOWN, .LEFT }, &[_]DirPad{DirPad.LEFT});
    try robot_kp_map.put(.{ .DOWN, .DOWN }, &[_]DirPad{});

    var robot_kp_pos = std.ArrayHashMap(Point, DirPad, HashCtx, true).init(allocator);
    defer robot_kp_pos.deinit();
    try robot_kp_pos.put(Point.init(0, -1), .LEFT);
    try robot_kp_pos.put(Point.init(0, 1), .RIGHT);
    try robot_kp_pos.put(Point.init(-1, 0), .UP);
    try robot_kp_pos.put(Point.init(1, 0), .DOWN);

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        var numeric: u16 = 0;

        var robot_kp = DirPad.A;
        var robot_mid = DirPad.A;
        for (row) |c| {
            const value = try std.fmt.charToDigit(c, 16);
            var path = try aStar(allocator, map[A], map[value]);
            defer path.deinit();

            var cost: u32 = 0;
            for (0..path.items.len - 1) |i| {
                const dir = path.items[i + 1].deltaP(path.items[i]);
                // Move robot 1 to satisfy dir, Get movements robot 1 needs to move to kp dir
                var move_mid = robot_kp_map.get(.{ robot_kp, robot_kp_pos.get(dir).? }).?;
                robot_kp = robot_kp_pos.get(dir).?; // Move kp robot, order does not matter
                for (move_mid) |dp| {
                    cost += robot_cost_map.get(.{ robot_mid, dp }).? + 1; // Pressing A costs 1
                    robot_mid = dp;
                }

                // Move mid back to A to press left.
                cost += robot_cost_map.get(.{ robot_mid, .A }).? + 1;
                robot_mid = .A;
                cost += 1; // Press A to move robot_kp
                // KP is now on 0, move robot_kp back
                move_mid = robot_kp_map.get(.{ robot_kp, .A }).?;
                robot_kp = .A;
                for (move_mid) |dp| {
                    cost += robot_cost_map.get(.{ robot_mid, dp }).? + 1; // Pressing A costs 1
                    robot_mid = dp;
                }
                cost += 1; // Press A to put the value in
                printa(cost);
                break;
            }

            _ = map[value];
            break;
        }
        numeric = try std.fmt.parseInt(u16, row[0 .. row.len - 1], 10);
        break;
    }
}

fn dirBounds(p: Point) bool {
    return 0 <= p.row and p.row < 2 and 0 <= p.col and p.col < 3 and
        !p.eq(Point.init(0, 0));
}

// const keypad = [_][3]u8{
//     .{ 7, 8, 9 },
//     .{ 4, 5, 6 },
//     .{ 1, 2, 3 },
//     .{ X, 0, A },
// };
// const dirpad = [_][3]u8{
//     .{ N, U, Ad },
//     .{ L, D, R },
// };

// Find sequence from A to 0
// {0,-1}. -> r1 to R (LDALAA), D (RR)
// Robot 1 need to move keypad D L L (keypad at 0) A -> R R U (keypad at A) A for 0
// Robot 1 is now at A, keypad 0 // Robot 1 always resets to A to press keypad

// Robot 2 needs to move L D A -> robot 1 moves to R.
// then             move L A -> robot 1 moves to U
// then             move A -> robot 1 moves to L

// Robot 1 have Dirpad+A
// Robot 2 have only dir pad
// LDA LA A RRUA DA A LUA RA | LDLA RRUA DA UA LDA RUA LDLA RUA RA A | DA UA LDLA RA RUA A A DA LUA RA
//
// LDA   move robot 2 to U D, move robot 1 to R
// LA    move robot 2 to L, move robot 1 to D
// A     move robot 2 move robot 1 to L
// RRUA  move robot 2 to D R A, robot 1 moves keypad to 0
// DA    move robot 2 to R, move robot 1 to D
// A     robot 2, move robot 1 to R
// LUA   move robot 2 to D U, move robot 1 to A
// RA    move robot 2 to A, robot 1 presses A -> keypad 0  -> 18 steps for 0

const dirpad = [_][3]u8{
    .{ N, U, Ad },
    .{ L, D, R },
};

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
                if (curr.eq(start)) {
                    break;
                }
                try path.append(curr);
                curr = edges[curr.r()][curr.c()];
            }
            try path.append(start);
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
            if (g_score[next_row][next_col] > tmp_g_score) {
                edges[next_row][next_col] = state.pos;
            }
            g_score[next_row][next_col] = tmp_g_score;
            const new_f_score = tmp_g_score + next_pos.manhattan(goal);
            f_score[next_row][next_col] = new_f_score;
            try pqueue.add(.{ .count = new_f_score, .pos = next_pos });
        }
    }

    return path;
}
