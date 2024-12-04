const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const expect = std.testing.expect;
const time = std.time;

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000_000);
        writer.print("\nTime taken: {d:.10}s\n", .{elapsed}) catch {};
    }
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    // const allocator = gpa.allocator();
    var buffer: [23_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    const input_attributes = try myf.getDelimType(input);
    var matrix = std.ArrayList([]const u8).init(allocator);
    defer matrix.deinit();

    var in_iter = std.mem.splitSequence(u8, input, if (input_attributes.delim == .CRLF) "\r\n" else "\n");
    while (in_iter.next()) |row| if (row.len == input_attributes.row_len) try matrix.append(row);

    const mat = matrix.items;
    const rows = mat.len;
    const cols = input_attributes.row_len;
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        part1(mat, rows, cols),
        part2(mat, rows, cols),
    });
}

inline fn part2(mat: [][]const u8, rows: usize, cols: usize) u32 {
    var sum: u32 = 0;
    for (0..rows - 2) |i| {
        for (0..cols - 2) |j| {
            const diagL = .{ mat[i][j], mat[i + 1][j + 1], mat[i + 2][j + 2] };
            const diagR = .{ mat[i][j + 2], mat[i + 1][j + 1], mat[i + 2][j] };
            if ((std.mem.eql(u8, &diagL, "MAS") or std.mem.eql(u8, &diagL, "SAM")) and
                (std.mem.eql(u8, &diagR, "MAS") or std.mem.eql(u8, &diagR, "SAM"))) sum += 1;
        }
    }
    return sum;
}

fn part1(mat: [][]const u8, rows: usize, cols: usize) u32 {
    const F4 = struct {
        inline fn getRow(m: [][]const u8, i: usize, j: usize) [4]u8 {
            return .{ m[i][j], m[i][j + 1], m[i][j + 2], m[i][j + 3] };
        }
        inline fn getDiagLeft(m: [][]const u8, i: usize, j: usize) [4]u8 {
            return .{ m[i][j], m[i + 1][j + 1], m[i + 2][j + 2], m[i + 3][j + 3] };
        }
        inline fn getDiagRight(m: [][]const u8, i: usize, j: usize) [4]u8 {
            return .{ m[i][j + 3], m[i + 1][j + 2], m[i + 2][j + 1], m[i + 3][j] };
        }
        inline fn getVert(m: [][]const u8, i: usize, j: usize) [4]u8 {
            return .{ m[i][j], m[i + 1][j], m[i + 2][j], m[i + 3][j] };
        }
    };

    var sum: u32 = 0;
    for (0..rows - 3) |i| {
        for (0..cols - 3) |j| {
            inline for (.{
                F4.getRow(mat, i, j),
                F4.getDiagLeft(mat, i, j),
                F4.getDiagRight(mat, i, j),
                F4.getVert(mat, i, j),
            }) |arr| {
                inline for (.{ "XMAS", "SAMX" }) |word| {
                    if (std.mem.eql(u8, &arr, word)) sum += 1;
                }
            }
        }
        for (cols - 3..cols) |k| {
            const vert = F4.getVert(mat, i, k);
            inline for (.{ "XMAS", "SAMX" }) |word| {
                if (std.mem.eql(u8, &vert, word)) sum += 1;
            }
        }
    }
    for (rows - 3..rows) |i| {
        for (0..cols - 3) |j| {
            const row = F4.getRow(mat, i, j);
            inline for (.{ "XMAS", "SAMX" }) |word| {
                if (std.mem.eql(u8, &row, word)) sum += 1;
            }
        }
    }
    return sum;
}
