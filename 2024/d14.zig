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

        const robot_row, const robot_col = part1_robot(100, robot, rows, cols);
        if (robot_row != hori_line and robot_col != vert_line)
            quad[@mod(robot_row / (hori_line + 1), 2)][@mod(robot_col / (vert_line + 1), 2)] += 1;
    }

    var p2_sum: ResT = 0;

    var next_map = std.AutoArrayHashMap(Vec2, void).init(allocator);
    try next_map.ensureTotalCapacity(list.items.len);
    defer next_map.deinit();
    for (0..1_000_000_000) |i| {
        next_map.clearRetainingCapacity();
        for (list.items) |*robot| {
            part2_robot(robot, rows, cols);
            next_map.putAssumeCapacity(robot.*[0], {});
        }
        if (next_map.count() == list.items.len) {
            printRobotsRoom(allocator, rows, cols, list.items);
            p2_sum = @intCast(i);
            p2_sum += 1;
            break;
        }

        // Old solution:
        // if (next_map.count() != list.items.len) continue;
        // if (dfs(allocator, next_map)) {
        //     printRobotsRoom(allocator, rows, cols, list.items);
        //     p2_sum = @intCast(i);
        //     p2_sum += 1;
        //     break;
        // }
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        @reduce(Op.Mul, @as(@Vector(4, ResT), @bitCast(quad))),
        p2_sum,
    });
}

fn part1_robot(steps: T, robot: [2]Vec2, rows: u8, cols: u8) [2]ResT {
    var pos, const dir = robot;
    pos = pos + Vec2{ steps, steps } * dir;

    pos[0] = @mod(pos[0], rows);
    pos[1] = @mod(pos[1], cols);

    const row, const col = pos;
    return .{ @intCast(row), @intCast(col) };
}

fn part2_robot(robot: *[2]Vec2, rows: u8, cols: u8) void {
    robot.*[0] = robot.*[0] + robot.*[1];
    robot.*[0][0] = @mod(robot.*[0][0], rows);
    robot.*[0][1] = @mod(robot.*[0][1], cols);
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

pub fn printRobotsRoom(allocator: Allocator, rows: u8, cols: u8, robots: [][2]Vec2) void {
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

    for (robots) |robot| {
        const pos = robot[0];
        matrix[@intCast(pos[0])][@intCast(pos[1])] = 'X';
    }
    for (matrix) |arr| {
        stdout.print("{s}\n", .{arr}) catch unreachable;
    }
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
