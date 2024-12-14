const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = std.debug.print;
const printA = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;
const Op = std.builtin.ReduceOp;

const T = i32;
const ResT = u32;
const Vec2 = @Vector(2, T);

const IDVec2 = packed struct { id: u16, robot: Vec2 };

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input = @embedFile("in/d14.txt");
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    const rows: u8 = 103; // 7, 103
    const cols: u8 = 101; // 11, 101
    const vert_line = cols / 2;
    const hori_line = rows / 2;
    var quad: [2][2]ResT = @bitCast([_]ResT{0} ** 4);

    var list = std.ArrayList([2]Vec2).init(allocator);
    defer list.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    var idx: ResT = 0;
    while (in_iter.next()) |row| {
        const robot = getPosDir(row);
        try list.append(robot);
        idx += 1;

        const robot_row, const robot_col = moveRobot(100, robot, rows, cols);
        if (robot_row != hori_line and robot_col != vert_line)
            quad[@mod(robot_row / (hori_line + 1), 2)][@mod(robot_col / (vert_line + 1), 2)] += 1;
    }

    var p2_sum: ResT = 0;

    var map = std.AutoArrayHashMap([2]ResT, void).init(allocator);
    try map.ensureTotalCapacity(list.items.len);
    defer map.deinit();
    for (1..10000) |i| {
        map.clearRetainingCapacity();
        for (list.items) |robot| map.putAssumeCapacity(moveRobot(@intCast(i), robot, rows, cols), {});
        if (map.count() == list.items.len) {
            printRobotsRoom(allocator, rows, cols, map.keys());
            p2_sum = @intCast(i);
            break;
        }

        // Old solution:
        // if (next_map.count() != list.items.len) continue;
        // if (dfs(allocator, next_map)) {
        //     printRobotsRoom(allocator, rows, cols, list.items);
        //     p2_sum = @intCast(i);
        //     break;
        // }
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        @reduce(Op.Mul, @as(@Vector(4, ResT), @bitCast(quad))),
        p2_sum,
    });

    try crt_p2_solution(allocator, list, rows, cols);
}

fn crt_p2_solution(allocator: Allocator, list: std.ArrayList([2]Vec2), rows: u8, cols: u8) !void {
    // https://www.reddit.com/r/adventofcode/comments/1hdvhvu/2024_day_14_solutions/m1zws1g/
    var map = std.AutoArrayHashMap([2]ResT, void).init(allocator);
    try map.ensureTotalCapacity(list.items.len);
    defer map.deinit();

    var x = std.ArrayList(f32).init(allocator);
    var y = std.ArrayList(f32).init(allocator);
    try x.ensureTotalCapacity(list.items.len);
    try y.ensureTotalCapacity(list.items.len);
    defer x.deinit();
    defer y.deinit();

    var var_x: f64 = 10000;
    var var_y: f64 = 10000;
    var remx: T = 0;
    var remy: T = 0;

    for (0..@max(rows, cols)) |i| {
        defer x.clearRetainingCapacity();
        defer y.clearRetainingCapacity();
        defer map.clearRetainingCapacity();
        for (list.items) |robot| {
            const res = moveRobot(@intCast(i), robot, rows, cols);
            const xx, const yy = res;
            x.appendAssumeCapacity(@floatFromInt(xx));
            y.appendAssumeCapacity(@floatFromInt(yy));
            map.putAssumeCapacity(res, {});
        }
        const var_x_res = myf.variance(x.items);
        if (var_x_res < var_x) {
            var_x = var_x_res;
            remx = @intCast(i);
            printRobotsRoom(allocator, rows, cols, map.keys());
        }
        const var_y_res = myf.variance(y.items);
        if (var_y_res < var_y) {
            var_y = var_y_res;
            remy = @intCast(i);
            printRobotsRoom(allocator, rows, cols, map.keys());
        }
    }
    const answer = try myf.crt(T, &[_]T{ remx, remy }, &[_]T{ rows, cols });
    for (list.items) |robot| map.putAssumeCapacity(moveRobot(@intCast(answer), robot, rows, cols), {});
    printRobotsRoom(allocator, rows, cols, map.keys());
    printA(answer);
}

fn moveRobot(steps: T, robot: [2]Vec2, rows: u8, cols: u8) [2]ResT {
    var pos, const dir = robot;
    pos = pos + Vec2{ steps, steps } * dir;

    pos[0] = @mod(pos[0], rows);
    pos[1] = @mod(pos[1], cols);

    const row, const col = pos;
    return .{ @intCast(row), @intCast(col) };
}

fn dfs(allocator: Allocator, map: std.AutoArrayHashMap(Vec2, void)) bool {
    const target_count = map.count();

    var stack = std.ArrayList(Vec2).init(allocator);
    defer stack.deinit();
    var visited = std.AutoArrayHashMap(Vec2, void).init(allocator);
    visited.ensureTotalCapacity(target_count) catch unreachable;
    defer visited.deinit();

    for (map.keys()) |vec| {
        stack.append(vec) catch unreachable;

        while (stack.items.len != 0) {
            const point = stack.pop();
            if (visited.get(point) != null) continue;
            visited.putAssumeCapacity(point, {});
            if (10 <= visited.count()) {
                return true;
            }

            const row, const col = point;
            for (myf.getKernel3x3(T, row, col)) |new_pos| {
                if (map.get(@as(Vec2, new_pos)) == null) continue;
                stack.append(new_pos) catch unreachable;
            }
        }
    }
    return false;
}

fn getPosDir(row: []const u8) [2]Vec2 {
    var start: usize = 0;
    while (row[start] != '=') : (start += 1) {}
    var comma: usize = start + 1;
    while (row[comma] != ',') : (comma += 1) {}
    var end: usize = comma + 1;
    while (std.ascii.isDigit(row[end]) or row[end] == '-') : (end += 1) {}
    const pos = Vec2{
        // Flipped as I prefer thinking of rows and cols. x,y confuse me as [y][x]...
        std.fmt.parseInt(T, row[comma + 1 .. end], 10) catch unreachable,
        std.fmt.parseInt(T, row[start + 1 .. comma], 10) catch unreachable,
    };
    start = end;
    while (row[start] != '=') : (start += 1) {}
    comma = start + 1;
    while (row[comma] != ',') : (comma += 1) {}
    const dir = Vec2{
        std.fmt.parseInt(T, row[comma + 1 .. row.len], 10) catch unreachable,
        std.fmt.parseInt(T, row[start + 1 .. comma], 10) catch unreachable,
    };
    return .{ pos, dir };
}

pub fn printRobotsRoom(allocator: Allocator, rows: u8, cols: u8, positions: anytype) void {
    const stdout = std.io.getStdOut().writer();
    var matrix = allocator.alloc([]u8, rows) catch unreachable;
    for (matrix) |*row| {
        row.* = allocator.alloc(u8, cols) catch unreachable;
        for (row.*) |*col| col.* = '.';
    }
    defer {
        for (matrix) |r| allocator.free(r);
        allocator.free(matrix);
    }

    for (positions) |pos| matrix[@intCast(pos[0])][@intCast(pos[1])] = 'X';
    for (matrix) |arr| stdout.print("{s}\n", .{arr}) catch unreachable;
    stdout.print("\n", .{}) catch unreachable;
}

test "example" {
    // const allocator = std.testing.allocator;
    const input = @embedFile("in/d14t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const rows: u8 = 7;
    const cols: u8 = 11;

    const steps = 100;

    const vert_line = cols / 2;
    const hori_line = rows / 2;
    var quad: [2][2]ResT = @bitCast([_]ResT{0} ** 4);

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |robot| {
        const pos_dir = getPosDir(robot);
        // const relative_pos = @mod(steps, walker(rows, cols, pos_dir));
        var pos, const dir = pos_dir;

        for (0..steps) |_| {
            pos = pos + dir;
            pos[0] = @mod(pos[0], rows);
            pos[1] = @mod(pos[1], cols);
        }
        // printRobotRoom(allocator, rows, cols, pos);
        const crow, const ccol = pos;
        const row: ResT = @intCast(crow);
        const col: ResT = @intCast(ccol);
        if (row == hori_line or col == vert_line) continue;

        quad[@mod(row / (hori_line + 1), 2)][@mod(col / (vert_line + 1), 2)] += 1;
    }
    const prod = @reduce(Op.Mul, @as(@Vector(4, ResT), @bitCast(quad)));
    print("{any}\n", .{prod});
}
