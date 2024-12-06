const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const expect = std.testing.expect;
const time = std.time;
const Complex = std.math.Complex;

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000_000);
        writer.print("\nTime taken: {d:.10}s\n", .{elapsed}) catch {};
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input = @embedFile("in/d06.txt");
    // End setup

    const input_attributes = try myf.getDelimType(input);
    var matrix = std.ArrayList([]const u8).init(allocator);
    defer matrix.deinit();

    // Imaginary numbers are usually mapped as Y = i, but I patternmatch REAL as Rows instead,..
    // Complex(REAL, IMAG)
    const ComplexT = Complex(f32);
    var start_row: u8 = 0;
    var start_col: u8 = 0;

    var rows: u8 = 0;
    const cols = input_attributes.row_len;
    var in_iter = std.mem.tokenizeSequence(u8, input, if (input_attributes.delim == .CRLF) "\r\n" else "\n");
    while (in_iter.next()) |row| {
        try matrix.append(row);
        if (std.mem.indexOf(u8, row, "^")) |idx| {
            start_row = rows;
            start_col = @truncate(idx);
        }
        rows += 1;
    }
    //
    const F = struct {
        inline fn inBounds(pos: ComplexT, max_row: f32, max_col: f32) bool {
            return 0 <= pos.re and pos.re < max_row and
                0 <= pos.im and pos.im < max_col;
        }
        inline fn complexToKey(c: ComplexT) [2]i16 {
            return .{ @intFromFloat(c.re), @intFromFloat(c.im) };
        }
        inline fn complexToKey2(c: ComplexT, d: ComplexT) [4]i16 {
            return .{ @intFromFloat(c.re), @intFromFloat(c.im), @intFromFloat(d.re), @intFromFloat(d.im) };
        }
    };

    const frows: f32 = @floatFromInt(rows);
    const fcols: f32 = @floatFromInt(cols);
    const rot_right = ComplexT.init(0, -1);
    // const rot_left = ComplexT.init(0, 1);

    var visited = std.AutoHashMap([2]i16, bool).init(allocator);
    defer visited.deinit();

    // REAL: row, IMAG: col
    var position = ComplexT.init(@floatFromInt(start_row), @floatFromInt(start_col));
    var direction = ComplexT.init(-1, 0); // Going upwards "^"
    const mat = matrix.items;
    while (true) {
        try visited.put(F.complexToKey(position), true);
        const next_pos = position.add(direction);
        if (!F.inBounds(next_pos, frows, fcols)) break;

        const row: u8 = @intFromFloat(next_pos.re);
        const col: u8 = @intFromFloat(next_pos.im);
        if (mat[row][col] == '#') {
            direction = direction.mul(rot_right);
        } else {
            position = next_pos;
        }
    }
    myf.printAny(visited.count());

    var p2_sum: u32 = 0;
    for (0..rows) |i| {
        for (0..cols) |j| {
            if (i == start_row and j == start_col or mat[i][j] == '#') continue;
            position = ComplexT.init(@floatFromInt(start_row), @floatFromInt(start_col));
            direction = ComplexT.init(-1, 0); // Going upwards "^"

            var visited_dir = std.AutoHashMap([4]i16, bool).init(allocator);
            defer visited_dir.deinit();
            while (true) {
                const res = try visited_dir.getOrPut(F.complexToKey2(position, direction));
                if (res.found_existing) {
                    p2_sum += 1;
                    break;
                }
                const next_pos = position.add(direction);
                if (!F.inBounds(next_pos, frows, fcols)) break;

                const row: u32 = @intFromFloat(next_pos.re);
                const col: u32 = @intFromFloat(next_pos.im);

                if (mat[row][col] == '#' or (row == i and col == j)) {
                    direction = direction.mul(rot_right);
                } else {
                    position = next_pos;
                }
            }
        }
    }
    myf.printAny(p2_sum);
}
