const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const Vec2 = @Vector(2, i8);

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [30_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup
    var input_matrix = try allocator.alloc([]u8, input_attributes.row_len);
    defer allocator.free(input_matrix);

    const split = std.mem.indexOf(u8, input, "\n\n").?;

    var start_row: u8 = 0;
    var start_col: u8 = 0;
    var grid_iter = std.mem.tokenizeScalar(u8, input[0..split], '\n');
    for (input_matrix, 0..) |*row, i| {
        row.* = @constCast(grid_iter.next().?);
        if (std.mem.indexOfScalar(u8, row.*, '@')) |j| {
            start_row = @intCast(i);
            start_col = @intCast(j);
        }
    }
    const movement = input[split + 2 .. input.len - 1];
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
        if (arrow == '\n') continue;
        const dir = getDir(arrow);

        const next_step: Vec2 = curr + dir;
        switch (getMatrixElem(matrix, next_step)) {
            'O' => {
                var find_empty = next_step + dir;
                while (true) {
                    switch (getMatrixElem(matrix, find_empty)) {
                        'O' => find_empty = find_empty + dir,
                        '.' => {
                            setMatrixElem(&matrix, find_empty, 'O');
                            setMatrixElem(&matrix, next_step, '.');
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
        if (arrow == '\n') continue;
        const dir = getDir(arrow);

        const next_step: Vec2 = curr + dir;
        switch (getMatrixElem(matrix, next_step)) {
            '#' => continue,
            '.' => curr = next_step,
            else => |elem| {
                if (arrow == '<' or arrow == '>') {
                    if (moveBoxLR(&matrix, dir, next_step)) curr = next_step;
                } else {
                    const left, const right = genBox(elem, next_step);

                    var early_exit = false;
                    if (canMoveChildren(matrix, dir, left, &early_exit) and
                        canMoveChildren(matrix, dir, right, &early_exit))
                    {
                        moveBoxUD(&matrix, dir, left);
                        moveBoxUD(&matrix, dir, right);
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
        setMatrixElem(matrix, next_step, getMatrixElem(matrix.*, half_step));
        setMatrixElem(matrix, half_step, getMatrixElem(matrix.*, curr_step));
        setMatrixElem(matrix, curr_step, '.');
        return true;
    }
    return false;
}

fn moveBoxUD(matrix: *[][]u8, dir: Vec2, half_box: Vec2) void {
    const next_step = half_box + dir;
    const elem = getMatrixElem(matrix.*, next_step);
    if (elem == '.') {
        setMatrixElem(matrix, next_step, getMatrixElem(matrix.*, half_box));
        setMatrixElem(matrix, half_box, '.');
        return;
    }

    const left, const right = genBox(elem, next_step);
    moveBoxUD(matrix, dir, left);
    moveBoxUD(matrix, dir, right);
    setMatrixElem(matrix, next_step, getMatrixElem(matrix.*, half_box));
    setMatrixElem(matrix, half_box, '.');
}

fn canMoveChildren(matrix: [][]u8, dir: Vec2, half_box: Vec2, early_exit: *bool) bool {
    if (early_exit.*) return true;
    const elem = getMatrixElem(matrix, half_box);
    if (elem == '.') return true;
    if (elem == '#') {
        early_exit.* = true;
        return false;
    }
    const left, const right = genBox(elem, half_box + dir);

    return canMoveChildren(matrix, dir, left, early_exit) and
        canMoveChildren(matrix, dir, right, early_exit);
}

fn genBox(elem: u8, step: Vec2) [2]Vec2 {
    return if (elem == '[')
        .{ step, step + getDir('>') }
    else
        .{ step + getDir('<'), step };
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

fn setMatrixElem(matrix: *[][]u8, robot: Vec2, elem: u8) void {
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
