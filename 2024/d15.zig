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
    // const input = @embedFile("in/d06t.txt");
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    // std.debug.print("{s}\n", .{input});
}

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d15ttt.txt");
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

    const matrix = try expandMatrixWidth(allocator, input_matrix);
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

    const curr: Vec2 = .{ @intCast(start_row), @intCast(start_col * 2) };

    printRobotMat(matrix, curr);
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

        // myf.waitForInput();
        // printRobotMat(matrix, curr);
        // prints([_]u8{arrow});
    }
    printRobotMat(matrix, curr);
    printa(boxValues(matrix));
}

pub fn expandMatrixWidth(alloc: Allocator, matrix: anytype) ![][]@TypeOf(matrix[0][0]) {
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

// test "part1" {
//     const allocator = std.testing.allocator;
//     var list = std.ArrayList(i8).init(allocator);
//     defer list.deinit();

//     const input = @embedFile("in/d15.txt");
//     const input_attributes = try myf.getInputAttributes(input);

//     const dim: u8 = @intCast(input_attributes.row_len);

//     const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
//     defer allocator.free(double_delim);

//     var grid_movement_iter = std.mem.tokenizeSequence(u8, input, double_delim);

//     const input_matrix = try allocator.alloc([]const u8, dim);
//     defer allocator.free(input_matrix);
//     var grid_iter = std.mem.tokenizeSequence(u8, grid_movement_iter.next().?, input_attributes.delim);

//     var start_row: u8 = 0;
//     var start_col: u8 = 0;
//     for (input_matrix, 0..) |*row, i| {
//         row.* = grid_iter.next().?;
//         if (std.mem.indexOfScalar(u8, row.*, '@')) |j| {
//             start_row = @intCast(i);
//             start_col = @intCast(j);
//         }
//     }
//     try expect(start_row != 0 and start_col != 0);

//     var matrix = try myf.copyMatrix(allocator, input_matrix);
//     matrix[start_row][start_col] = '.';
//     defer myf.freeMatrix(allocator, matrix);

//     var curr: Vec2 = .{ @intCast(start_row), @intCast(start_col) };
//     const movement = grid_movement_iter.next().?;
//     for (movement, 0..) |arrow, i| {
//         _ = i;
//         if (arrow == '\n' or arrow == '\r') continue;
//         var next_step: Vec2 = undefined;
//         const dir = switch (arrow) {
//             '^' => Vec2{ -1, 0 },
//             '>' => Vec2{ 0, 1 },
//             'v' => Vec2{ 1, 0 },
//             else => Vec2{ 0, -1 },
//         };
//         next_step = curr + dir;
//         // const r, const c = vec2ToCoord(next_step);
//         // const elem = matrix[r][c];
//         const elem = getMatrixElem(matrix, next_step);
//         if (elem == '#') continue;
//         if (elem == 'O') {
//             const box = next_step;
//             var find_empty = box + dir;
//             while (true) {
//                 switch (getMatrixElem(matrix, find_empty)) {
//                     '.' => {
//                         setMatrixelem(&matrix, find_empty, 'O');
//                         setMatrixelem(&matrix, next_step, '.');
//                         curr = next_step;
//                         break;
//                     },
//                     'O' => {
//                         find_empty = find_empty + dir;
//                     },
//                     else => break,
//                 }
//             }
//         } else {
//             curr = next_step;
//         }
//         // myf.waitForInput();
//         // printRobotMat(matrix, curr);
//         // prints([_]u8{arrow});
//     }
//     printRobotMat(matrix, curr);
//     printa(boxValues(matrix, 'O'));
// }

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
