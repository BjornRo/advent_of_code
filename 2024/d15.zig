const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const VecT = i8;
const Vec2 = @Vector(2, VecT);

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

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    const dim: u8 = @intCast(input_attributes.row_len);

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var grid_movement_iter = std.mem.tokenizeSequence(u8, input, double_delim);

    var input_matrix = try allocator.alloc([]u8, dim);
    defer allocator.free(input_matrix);
    var grid_iter = std.mem.tokenizeSequence(u8, grid_movement_iter.next().?, input_attributes.delim);
    const movement = grid_movement_iter.next().?;

    var start_row: u8 = 0;
    var start_col: u8 = 0;
    for (input_matrix, 0..) |*row, i| {
        row.* = @constCast(grid_iter.next().?);
        if (std.mem.indexOfScalar(u8, row.*, '@')) |j| {
            start_row = @intCast(i);
            start_col = @intCast(j);
        }
    }
    const p2 = try part2(allocator, input_matrix, movement, start_row, start_col, false);
    const p1 = part1(&input_matrix, movement, start_row, start_col, false); // has to be after p2
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1, p2 });
}

fn part1(
    input_matrix: *[][]u8,
    movement: []const u8,
    start_row: u8,
    start_col: u8,
    print_final_grid: bool,
) u64 {
    var matrix = input_matrix.*;
    // var matrix = try myf.copyMatrix(allocator, input_matrix);
    // defer myf.freeMatrix(allocator, matrix);
    matrix[start_row][start_col] = '.'; // Totally uneccessary, but nicer prints

    var curr: Vec2 = .{ @intCast(start_row), @intCast(start_col) };

    for (movement) |arrow| {
        if (arrow == '\n' or arrow == '\r') continue;
        const dir = getDir(arrow);

        const next_step: Vec2 = curr + dir;
        switch (getMatrixElem(matrix, next_step)) {
            'O' => {
                var find_empty = next_step + dir;
                while (true) {
                    switch (getMatrixElem(matrix, find_empty)) {
                        'O' => find_empty = find_empty + dir,
                        '.' => {
                            setMatrixelem(&matrix, find_empty, 'O');
                            setMatrixelem(&matrix, next_step, '.');
                            curr = next_step;
                            break;
                        },
                        else => break,
                    }
                }
            },
            '#' => continue,
            else => curr = next_step,
        }
    }
    if (print_final_grid) printRobotMat(matrix, curr);
    return boxValues(matrix, 'O');
}

fn part2(
    allocator: Allocator,
    input_matrix: []const []const u8,
    movement: []const u8,
    start_row: u8,
    start_col: u8,
    print_final_grid: bool,
) !u64 {
    var matrix = try expandMatrixWidth(allocator, input_matrix);
    matrix[start_row][start_col * 2] = '.'; // Totally uneccessary, but nicer prints
    matrix[start_row][start_col * 2 + 1] = '.'; // Totally uneccessary, but nicer prints
    defer myf.freeMatrix(allocator, matrix);

    for (0..matrix.len) |i| {
        for (0..matrix[0].len / 2) |j| {
            const new_j = j * 2;
            if (matrix[i][new_j] == 'O') {
                matrix[i][new_j] = '[';
                matrix[i][new_j + 1] = ']';
            }
        }
    }
    var curr: Vec2 = .{ @intCast(start_row), @intCast(start_col * 2) };

    for (movement) |arrow| {
        if (arrow == '\n' or arrow == '\r') continue;
        const dir = getDir(arrow);

        const next_step: Vec2 = curr + dir;
        switch (getMatrixElem(matrix, next_step)) {
            '#' => continue,
            '.' => curr = next_step,
            else => |elem| {
                if (arrow == '<' or arrow == '>') {
                    if (moveBoxLR(&matrix, dir, next_step)) curr = next_step;
                } else {
                    const box: [2]Vec2 = if (elem == '[')
                        .{ next_step, next_step + Vec2{ 0, 1 } }
                    else
                        .{ next_step + Vec2{ 0, -1 }, next_step };

                    var early_exit = false;
                    if (canMoveChildren(matrix, dir, box, &early_exit)) {
                        moveBoxUD(&matrix, dir, box);
                        curr = next_step;
                    }
                }
            },
        }
    }
    if (print_final_grid) printRobotMat(matrix, curr);
    return boxValues(matrix, '[');
}

fn moveBoxLR(matrix: *[][]u8, dir: Vec2, curr_step: Vec2) bool {
    const curr_elem = getMatrixElem(matrix.*, curr_step);
    if (curr_elem == '.') return true;
    if (curr_elem == '#') return false;

    const half_step = curr_step + dir; // Half box
    const next_step = half_step + dir; // Full box
    if (moveBoxLR(matrix, dir, next_step)) {
        // Curr step is either [,]. Does not matter which, just naive swap.
        const half_box_elem = getMatrixElem(matrix.*, half_step);
        const curr_box_elem = getMatrixElem(matrix.*, curr_step);
        setMatrixelem(matrix, next_step, half_box_elem);
        setMatrixelem(matrix, half_step, curr_box_elem);
        setMatrixelem(matrix, curr_step, '.');
        return true;
    }
    return false;
}

fn moveBoxUD(matrix: *[][]u8, dir: Vec2, curr_box: [2]Vec2) void {
    const left_par, const right_par = curr_box;
    const left_child = left_par + dir;
    const right_child = right_par + dir;
    const left_child_elem = getMatrixElem(matrix.*, left_child);
    const right_child_elem = getMatrixElem(matrix.*, right_child);

    const left_child_box = .{ left_child + getDir('<'), left_child };
    const right_child_box = .{ right_child, right_child + getDir('>') };

    if (left_child_elem == ']' and right_child_elem == '[') {
        moveBoxUD(matrix, dir, left_child_box);
        moveBoxUD(matrix, dir, right_child_box);
    } else if (left_child_elem == ']' and right_child_elem != '[') {
        moveBoxUD(matrix, dir, left_child_box);
    } else if (left_child_elem != ']' and right_child_elem == '[') {
        moveBoxUD(matrix, dir, right_child_box);
    } else if (left_child_elem == '[' and right_child_elem == ']') {
        moveBoxUD(matrix, dir, .{ left_child, right_child });
    }
    setMatrixelem(matrix, left_child, '[');
    setMatrixelem(matrix, right_child, ']');
    setMatrixelem(matrix, left_par, '.');
    setMatrixelem(matrix, right_par, '.');
}

fn canMoveChildren(matrix: [][]u8, dir: Vec2, curr_box: [2]Vec2, early_exit: *bool) bool {
    if (early_exit.*) return true;
    // Find all children, then move then in the direction.
    // A box can only have 1 or 2 childrens.
    const left_par, const right_par = curr_box;
    const left_child = left_par + dir;
    const right_child = right_par + dir;
    const left_child_elem = getMatrixElem(matrix, left_child);
    const right_child_elem = getMatrixElem(matrix, right_child);

    if (left_child_elem == '#' or right_child_elem == '#') {
        early_exit.* = true;
        return false;
    }
    if (left_child_elem == '.' and right_child_elem == '.') return true;

    const left_child_box = .{ left_child + getDir('<'), left_child };
    const right_child_box = .{ right_child, right_child + getDir('>') };

    if (left_child_elem == ']' and right_child_elem == '[') {
        return canMoveChildren(matrix, dir, left_child_box, early_exit) and
            canMoveChildren(matrix, dir, right_child_box, early_exit);
    } else if (left_child_elem == ']' and right_child_elem != '[') {
        return canMoveChildren(matrix, dir, left_child_box, early_exit);
    } else if (left_child_elem != ']' and right_child_elem == '[') {
        return canMoveChildren(matrix, dir, right_child_box, early_exit);
    } // else if (left_child_elem == '[' and right_child_elem == ']') {
    return canMoveChildren(matrix, dir, .{ left_child, right_child }, early_exit);
}

fn expandMatrixWidth(alloc: Allocator, matrix: anytype) ![][]@TypeOf(matrix[0][0]) {
    const T = @TypeOf(matrix[0][0]);

    const row_len = matrix.len;
    const col_len = matrix[0].len;
    var new_matrix = try alloc.alloc([]T, row_len);

    for (0..row_len) |i| {
        new_matrix[i] = try alloc.alloc(T, col_len * 2);
        for (0..(col_len * 2)) |j| {
            const source_col = j / 2;
            new_matrix[i][j] = matrix[i][source_col];
        }
    }

    return new_matrix;
}

fn boxValues(matrix: []const []const u8, scalar: u8) u64 {
    const col_len = matrix[0].len - 1;
    var sum: u64 = 0;
    for (1..matrix.len - 1) |i| {
        for (1..col_len) |j| {
            if (matrix[i][j] == scalar) {
                sum += 100 * i + j;
            }
        }
    }
    return sum;
}

fn setMatrixelem(matrix: *[][]u8, robot: Vec2, elem: u8) void {
    const r, const c = vec2ToCoord(robot);
    matrix.*[r][c] = elem;
}

fn getMatrixElem(matrix: anytype, robot: Vec2) u8 {
    const r, const c = vec2ToCoord(robot);
    return matrix[r][c];
}

fn vec2ToCoord(robot: Vec2) [2]u8 {
    const i, const j = robot;
    return .{ @intCast(i), @intCast(j) };
}

fn getDir(arrow: u8) Vec2 {
    return switch (arrow) {
        '^' => Vec2{ -1, 0 },
        '>' => Vec2{ 0, 1 },
        'v' => Vec2{ 1, 0 },
        else => Vec2{ 0, -1 },
    };
}

fn printRobotMat(matrix: anytype, robot: ?Vec2) void {
    if (robot) |rb| {
        const i, const j = vec2ToCoord(rb);
        const elem = &matrix[i][j];
        const tmp = elem.*;
        elem.* = '@';
        defer elem.* = tmp;
        myf.printMatStr(matrix);
    } else {
        myf.printMatStr(matrix);
    }
}

test "part1" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d15.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const dim: u8 = @intCast(input_attributes.row_len);

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var grid_movement_iter = std.mem.tokenizeSequence(u8, input, double_delim);

    const input_matrix = try allocator.alloc([]const u8, dim);
    defer allocator.free(input_matrix);
    var grid_iter = std.mem.tokenizeSequence(u8, grid_movement_iter.next().?, input_attributes.delim);

    var start_row: u8 = 0;
    var start_col: u8 = 0;
    for (input_matrix, 0..) |*row, i| {
        row.* = grid_iter.next().?;
        if (std.mem.indexOfScalar(u8, row.*, '@')) |j| {
            start_row = @intCast(i);
            start_col = @intCast(j);
        }
    }
    try expect(start_row != 0 and start_col != 0);

    var matrix = try myf.copyMatrix(allocator, input_matrix);
    matrix[start_row][start_col] = '.';
    defer myf.freeMatrix(allocator, matrix);

    var curr: Vec2 = .{ @intCast(start_row), @intCast(start_col) };
    const movement = grid_movement_iter.next().?;
    for (movement, 0..) |arrow, i| {
        _ = i;
        if (arrow == '\n' or arrow == '\r') continue;
        var next_step: Vec2 = undefined;
        const dir = switch (arrow) {
            '^' => Vec2{ -1, 0 },
            '>' => Vec2{ 0, 1 },
            'v' => Vec2{ 1, 0 },
            else => Vec2{ 0, -1 },
        };
        next_step = curr + dir;
        // const r, const c = vec2ToCoord(next_step);
        // const elem = matrix[r][c];
        const elem = getMatrixElem(matrix, next_step);
        if (elem == '#') continue;
        if (elem == 'O') {
            const box = next_step;
            var find_empty = box + dir;
            while (true) {
                switch (getMatrixElem(matrix, find_empty)) {
                    '.' => {
                        setMatrixelem(&matrix, find_empty, 'O');
                        setMatrixelem(&matrix, next_step, '.');
                        curr = next_step;
                        break;
                    },
                    'O' => {
                        find_empty = find_empty + dir;
                    },
                    else => break,
                }
            }
        } else {
            curr = next_step;
        }
        // myf.waitForInput();
        // printRobotMat(matrix, curr);
        // prints([_]u8{arrow});
    }
    printRobotMat(matrix, curr);
    printa(boxValues(matrix, 'O'));
}

test "part2" {
    const allocator = std.testing.allocator;

    const input = @embedFile("in/d15.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const dim: u8 = @intCast(input_attributes.row_len);

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var grid_movement_iter = std.mem.tokenizeSequence(u8, input, double_delim);

    const input_matrix = try allocator.alloc([]const u8, dim);
    defer allocator.free(input_matrix);
    var grid_iter = std.mem.tokenizeSequence(u8, grid_movement_iter.next().?, input_attributes.delim);

    var start_row: u8 = 0;
    var start_col: u8 = 0;
    for (input_matrix, 0..) |*row, i| {
        row.* = grid_iter.next().?;
        if (std.mem.indexOfScalar(u8, row.*, '@')) |j| {
            start_row = @intCast(i);
            start_col = @intCast(j);
        }
    }
    try expect(start_row != 0 and start_col != 0);

    var matrix = try expandMatrixWidth(allocator, input_matrix);
    matrix[start_row][start_col * 2] = '.';
    matrix[start_row][start_col * 2 + 1] = '.';
    defer myf.freeMatrix(allocator, matrix);

    for (0..matrix.len) |i| {
        for (0..matrix[0].len / 2) |j| {
            const new_j = j * 2;
            if (matrix[i][new_j] == 'O') {
                matrix[i][new_j] = '[';
                matrix[i][new_j + 1] = ']';
            }
        }
    }

    var curr: Vec2 = .{ @intCast(start_row), @intCast(start_col * 2) };

    const movement = grid_movement_iter.next().?;
    for (movement, 0..) |arrow, i| {
        _ = i;
        if (arrow == '\n' or arrow == '\r') continue;
        var next_step: Vec2 = undefined;
        const dir = switch (arrow) {
            '^' => Vec2{ -1, 0 },
            '>' => Vec2{ 0, 1 },
            'v' => Vec2{ 1, 0 },
            else => Vec2{ 0, -1 },
        };
        next_step = curr + dir;
        // const r, const c = vec2ToCoord(next_step);
        // const elem = matrix[r][c];
        const elem = getMatrixElem(matrix, next_step);
        if (elem == '#') continue;
        if (elem == '.') {
            curr = next_step;
            continue;
        }
        // Either [,]
        var box: [2]Vec2 = undefined;
        if (arrow == '^' or arrow == 'v') {
            if (elem == '[') {
                box = .{ next_step, next_step + Vec2{ 0, 1 } };
            } else {
                box = .{ next_step + Vec2{ 0, -1 }, next_step };
            }
            if (canMoveChildren(matrix, dir, box)) {
                moveBoxUD(&matrix, dir, box);
                curr = next_step;
            }
            continue;
        }

        if (moveBoxLR(&matrix, dir, next_step)) {
            curr = next_step;
        }
    }
    printRobotMat(matrix, curr);
    printa(boxValues(matrix, '['));
}
