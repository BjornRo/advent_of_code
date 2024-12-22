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

const CostMove = struct {
    cost: u8, // including A's
    end_dir: DirPad, // The movers ending pos
};
const DirPad = enum {
    LEFT,
    RIGHT,
    UP,
    DOWN,
    A,
    const Self = @This();
    fn fromPos(p: Point) Self {
        if (p.row == -1) return .UP;
        if (p.row == 1) return .DOWN;
        if (p.col == -1) return .LEFT;
        if (p.col == 1) return .RIGHT;
        unreachable;
    }
};
const start_row = 3;
const start_col = 2;

// too high 204199
test "example" {
    const allocator = std.testing.allocator;

    const input = @embedFile("in/d21.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var sum: u64 = 0;

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        const numeric: u16 = try std.fmt.parseInt(u16, row[0 .. row.len - 1], 10);

        var move_mid: CostMove = undefined;

        var robot_kp = DirPad.A;
        var robot_mid = DirPad.A;
        var cost: u32 = 0;
        var curr_kp: u8 = A;
        for (row) |c| {
            const next_kp = try std.fmt.charToDigit(c, 16);
            var path = try aStar(allocator, map[curr_kp], map[next_kp]);
            defer path.deinit();
            curr_kp = next_kp;

            // First move keypad robot to the desired keypad location
            for (0..path.items.len - 1) |i| {
                // Move robot 1 to satisfy dir, Get movements robot 1 needs to move to kp dir
                const move_dir = DirPad.fromPos(path.items[i + 1].sub(path.items[i]));
                if (move_dir == robot_kp) { // If we are on the correct position, no need to move.
                    cost += 1; // We do not need to move mover, just press A
                    continue;
                }
                // If needs to move, then move back mover to A to move
                move_mid = getCostMove(robot_kp, move_dir);
                robot_kp = move_dir;
                robot_mid = move_mid.end_dir;
                cost += move_mid.cost;
                cost += getOnlyMoveCost(robot_mid, .A);
                robot_mid = .A;
                cost += 1; // Press A
            }

            // robot_kp != .A here , move robot is on A, we need to press keypad!
            // Move robot_kp to A
            move_mid = getCostMove(robot_kp, .A);
            robot_kp = .A;
            robot_mid = move_mid.end_dir;
            cost += move_mid.cost;
            cost += getOnlyMoveCost(robot_mid, .A);
            robot_mid = .A;
            cost += 1; // Press A

        }
        // [72, 70, 70, 68, 74]
        std.debug.print("{d}, {d}\n", .{ cost, numeric });
        sum += cost * numeric;
    }
    prints("");
    printa(sum);
}

/// Move keypad robot from X -> Y, assuming mover is at A
/// The mover should always reset to A to be able to move next robot
fn getCostMove(from: DirPad, to: DirPad) CostMove {
    return switch (from) {
        .A => return switch (to) {
            .LEFT => .{ .cost = 6, .end_dir = .LEFT },
            .UP => .{ .cost = 4, .end_dir = .LEFT },
            .DOWN => .{ .cost = 5, .end_dir = .LEFT },
            .RIGHT => .{ .cost = 3, .end_dir = .DOWN },
            else => unreachable,
        },
        .LEFT => return switch (to) {
            .A => .{ .cost = 6, .end_dir = .UP },
            .UP => .{ .cost = 5, .end_dir = .UP },
            .DOWN => .{ .cost = 2, .end_dir = .RIGHT },
            .RIGHT => .{ .cost = 3, .end_dir = .RIGHT },
            else => unreachable,
        },
        .UP => return switch (to) {
            .LEFT => .{ .cost = 5, .end_dir = .LEFT },
            .A => .{ .cost = 2, .end_dir = .RIGHT },
            .RIGHT => .{ .cost = 4, .end_dir = .DOWN },
            .DOWN => .{ .cost = 3, .end_dir = .DOWN },
            else => unreachable,
        },
        .RIGHT => return switch (to) {
            .A => .{ .cost = 2, .end_dir = .UP },
            .DOWN => .{ .cost = 4, .end_dir = .LEFT },
            .UP => .{ .cost = 5, .end_dir = .LEFT },
            .LEFT => .{ .cost = 5, .end_dir = .LEFT },
            else => unreachable,
        },
        .DOWN => return switch (to) {
            .A => .{ .cost = 5, .end_dir = .UP }, // .UP .RIGHT
            .RIGHT => .{ .cost = 2, .end_dir = .RIGHT },
            .UP => .{ .cost = 2, .end_dir = .UP },
            .LEFT => .{ .cost = 4, .end_dir = .LEFT },
            else => unreachable,
        },
    };
}

fn getOnlyMoveCost(from: DirPad, to: DirPad) u8 {
    return switch (from) {
        .LEFT => return switch (to) {
            .RIGHT => 2,
            .DOWN => 1,
            .UP => 2,
            .A => 3,
            .LEFT => 0,
        },
        .RIGHT => return switch (to) {
            .LEFT => 2,
            .DOWN => 1,
            .UP => 2,
            .A => 1,
            .RIGHT => 0,
        },
        .UP => return switch (to) {
            .A => 1,
            .DOWN => 1,
            .LEFT => 5,
            .RIGHT => 4,
            .UP => 0,
        },
        .DOWN => return switch (to) {
            .A => 2,
            .RIGHT => 2,
            .UP => 2,
            .LEFT => 4,
            .DOWN => 0,
        },
        .A => return switch (to) {
            .LEFT => 6,
            .UP => 4,
            .DOWN => 5,
            .RIGHT => 3,
            .A => 0,
        },
    };
}

// fn codeMover(allocator: Allocator, code: []const u8) !void {}

fn aStar(allocator: Allocator, start: Point, goal: Point) !std.ArrayList(Point) {
    const Path = myf.FixedBuffer(Point, rows * cols);
    const State = struct {
        count: CT,
        pos: Point,
        prev_dir: Point,
        path: Path,

        const Self = @This();

        fn cmp(_: void, a: Self, b: Self) std.math.Order {
            if (a.count < b.count) return .lt;
            if (a.count > b.count) return .gt;
            return .eq;
        }
    };
    const MAX: CT = std.math.maxInt(CT);
    const NULL_POINT = comptime Point.init(-1, -1);

    var g_score: [rows][cols]CT = undefined;
    var f_score: [rows][cols]CT = undefined;
    var prev_dir: [rows][cols]Point = undefined; // Punish zig zags
    for (0..rows) |i| {
        for (0..cols) |j| {
            g_score[i][j] = MAX;
            f_score[i][j] = MAX;
            prev_dir[i][j] = NULL_POINT;
        }
    }

    var path = std.ArrayList(Point).init(allocator);

    g_score[start.r()][start.c()] = 0;
    f_score[start.r()][start.c()] = start.manhattan(goal);

    var pqueue = PriorityQueue(State, void, State.cmp).init(allocator, undefined);
    defer pqueue.deinit();
    try pqueue.add(.{ .count = 0, .pos = start, .path = Path.init(), .prev_dir = NULL_POINT });

    while (pqueue.count() != 0) {
        const state = pqueue.remove();

        if (goal.eq(state.pos)) {
            var stpath = state.path;
            try path.append(start);
            for (stpath.getSlice()) |p| {
                try path.append(p);
            }
            // for (g_score) |row| {
            //     printa(row);
            // }
            // printa(path.items);
            // printa(state.count);
            // printa(pqueue.items);
            // myf.waitForInput();
            break;
        }

        for (myf.getNeighborOffset(CT)) |next_dir_| {
            const next_dir = Point.initA(next_dir_);
            const next_pos = state.pos.add(next_dir);
            if (!inBounds(next_pos)) continue;

            const row, const col = state.pos.cast();
            const tmp_g_score = g_score[row][col] + 1 +
                calcPenalty(state.prev_dir, next_dir, NULL_POINT, 1000);

            const next_row, const next_col = next_pos.cast();
            if (g_score[next_row][next_col] != MAX and tmp_g_score >= f_score[next_row][next_col]) {
                continue;
            }
            g_score[next_row][next_col] = tmp_g_score;
            prev_dir[next_row][next_col] = next_dir;

            const new_f_score = tmp_g_score + next_pos.manhattan(goal);
            f_score[next_row][next_col] = new_f_score;
            var new_state: State = .{ .count = new_f_score, .pos = next_pos, .path = state.path.copy(), .prev_dir = next_dir };
            try new_state.path.append(next_pos);
            try pqueue.add(new_state);
        }
    }

    return path;
}

inline fn calcPenalty(prev_dir: Point, next_dir: Point, comptime NULL_POINT: Point, comptime penalty: CT) CT {
    var pen = if (prev_dir.eq(NULL_POINT) or prev_dir.eq(next_dir)) 0 else penalty;
    pen += if (prev_dir.eq(Point.init(0, 1)) or prev_dir.eq(Point.init(0, -1))) 0 else 1;
    return pen;
}

//     var robot_kp_map = std.AutoArrayHashMap([2]DirPad, []const DirPad).init(allocator);
// defer robot_kp_map.deinit();

// try robot_kp_map.put(.{ .A, .LEFT }, &[_]DirPad{ DirPad.DOWN, DirPad.LEFT, DirPad.LEFT });
// try robot_kp_map.put(.{ .A, .UP }, &[_]DirPad{DirPad.LEFT});
// try robot_kp_map.put(.{ .A, .DOWN }, &[_]DirPad{ DirPad.DOWN, DirPad.LEFT });
// try robot_kp_map.put(.{ .A, .RIGHT }, &[_]DirPad{DirPad.DOWN});
// try robot_kp_map.put(.{ .A, .A }, &[_]DirPad{});
// try robot_kp_map.put(.{ .LEFT, .A }, &[_]DirPad{ DirPad.RIGHT, DirPad.RIGHT, DirPad.UP });
// try robot_kp_map.put(.{ .LEFT, .UP }, &[_]DirPad{ DirPad.RIGHT, DirPad.UP });
// try robot_kp_map.put(.{ .LEFT, .DOWN }, &[_]DirPad{DirPad.RIGHT});
// try robot_kp_map.put(.{ .LEFT, .RIGHT }, &[_]DirPad{ DirPad.RIGHT, DirPad.RIGHT });
// try robot_kp_map.put(.{ .LEFT, .LEFT }, &[_]DirPad{});
// try robot_kp_map.put(.{ .UP, .LEFT }, &[_]DirPad{ DirPad.DOWN, DirPad.LEFT });
// try robot_kp_map.put(.{ .UP, .A }, &[_]DirPad{DirPad.RIGHT});
// try robot_kp_map.put(.{ .UP, .RIGHT }, &[_]DirPad{ DirPad.DOWN, DirPad.RIGHT });
// try robot_kp_map.put(.{ .UP, .DOWN }, &[_]DirPad{DirPad.DOWN});
// try robot_kp_map.put(.{ .UP, .UP }, &[_]DirPad{});
// try robot_kp_map.put(.{ .RIGHT, .A }, &[_]DirPad{DirPad.UP});
// try robot_kp_map.put(.{ .RIGHT, .DOWN }, &[_]DirPad{DirPad.LEFT});
// try robot_kp_map.put(.{ .RIGHT, .UP }, &[_]DirPad{ DirPad.LEFT, DirPad.UP });
// try robot_kp_map.put(.{ .RIGHT, .LEFT }, &[_]DirPad{ DirPad.LEFT, DirPad.LEFT });
// try robot_kp_map.put(.{ .RIGHT, .RIGHT }, &[_]DirPad{});
// try robot_kp_map.put(.{ .DOWN, .A }, &[_]DirPad{ DirPad.RIGHT, DirPad.UP });
// try robot_kp_map.put(.{ .DOWN, .RIGHT }, &[_]DirPad{DirPad.RIGHT});
// try robot_kp_map.put(.{ .DOWN, .UP }, &[_]DirPad{DirPad.UP});
// try robot_kp_map.put(.{ .DOWN, .LEFT }, &[_]DirPad{DirPad.LEFT});
// try robot_kp_map.put(.{ .DOWN, .DOWN }, &[_]DirPad{});

// var robot_cost_map = std.AutoArrayHashMap([2]DirPad, u8).init(allocator);
// defer robot_cost_map.deinit();

// var robot_cost_map_raw = std.AutoArrayHashMap([2]DirPad, u8).init(allocator);
// defer robot_cost_map_raw.deinit();
// try robot_cost_map_raw.put(.{ .LEFT, .RIGHT }, 2);
// try robot_cost_map_raw.put(.{ .LEFT, .DOWN }, 1);
// try robot_cost_map_raw.put(.{ .LEFT, .UP }, 2);
// try robot_cost_map_raw.put(.{ .LEFT, .A }, 3);
// try robot_cost_map_raw.put(.{ .RIGHT, .DOWN }, 1);
// try robot_cost_map_raw.put(.{ .RIGHT, .UP }, 2);
// try robot_cost_map_raw.put(.{ .RIGHT, .LEFT }, 2);
// try robot_cost_map_raw.put(.{ .RIGHT, .A }, 1);
// try robot_cost_map_raw.put(.{ .UP, .A }, 1);
// try robot_cost_map_raw.put(.{ .UP, .DOWN }, 1);
// try robot_cost_map_raw.put(.{ .DOWN, .A }, 2);
// try robot_cost_map_raw.put(.{ .LEFT, .LEFT }, 0);
// try robot_cost_map_raw.put(.{ .RIGHT, .RIGHT }, 0);
// try robot_cost_map_raw.put(.{ .UP, .UP }, 0);
// try robot_cost_map_raw.put(.{ .A, .A }, 0);
// try robot_cost_map_raw.put(.{ .DOWN, .DOWN }, 0);
// for (robot_cost_map_raw.keys(), robot_cost_map_raw.values()) |key, value| {
//     const left, const right = key;
//     try robot_cost_map.put(key, value);
//     try robot_cost_map.put(.{ right, left }, value);
// }
