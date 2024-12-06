const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const expect = std.testing.expect;
const print = myf.printAny;
const time = std.time;
const Complex = std.math.Complex;

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
    var buffer: [550_000]u8 = undefined;
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

    // Imaginary numbers are usually mapped as Y = i, but I patternmatch REAL as Rows instead,..
    // Complex(REAL, IMAG)
    const ComplexT = Complex(i16);
    var start_row: i16 = 0;
    var start_col: i16 = 0;

    var rows: i16 = 0;
    const cols: i16 = @intCast(input_attributes.row_len);
    var in_iter = std.mem.tokenizeSequence(u8, input, if (input_attributes.delim == .CRLF) "\r\n" else "\n");
    while (in_iter.next()) |row| {
        try matrix.append(row);
        if (std.mem.indexOf(u8, row, "^")) |idx| {
            start_row = rows;
            start_col = @intCast(idx);
        }
        rows += 1;
    }

    //
    const F = struct {
        inline fn inBounds(pos: ComplexT, max_row: i16, max_col: i16) bool {
            return 0 <= pos.re and pos.re < max_row and 0 <= pos.im and pos.im < max_col;
        }
        inline fn complexTo32(c: ComplexT) u32 {
            return @bitCast([2]i16{ c.re, c.im });
        }
        inline fn u32Tou16(n: u32) [2]u16 {
            return @bitCast(n);
        }
        inline fn complexTo64(c: ComplexT, d: ComplexT) u64 {
            return @bitCast([4]i16{ c.re, c.im, d.re, d.im });
        }
    };

    const rot_right = ComplexT.init(0, -1);
    // // const rot_left = ComplexT.init(0, 1);

    var visited = std.AutoArrayHashMap(u32, void).init(allocator);
    defer visited.deinit();

    var direction = ComplexT.init(-1, 0); // Going upwards "^"
    var position = ComplexT.init(start_row, start_col);
    const mat = matrix.items;
    while (true) {
        try visited.put(F.complexTo32(position), {});
        const next_pos = position.add(direction);
        if (!F.inBounds(next_pos, rows, cols)) break;

        const row: u16 = @bitCast(next_pos.re);
        const col: u16 = @bitCast(next_pos.im);
        if (mat[row][col] == '#') {
            direction = direction.mul(rot_right);
        } else {
            position = next_pos;
        }
    }
    const visited_slice = visited.keys();
    var visited_dir = std.AutoArrayHashMap(u64, void).init(allocator);
    defer visited_dir.deinit();

    var p2_sum: u16 = 0;
    for (visited_slice[1..]) |key| {
        defer visited_dir.clearRetainingCapacity();

        const i, const j = F.u32Tou16(key);
        position = ComplexT.init(start_row, start_col);
        direction = ComplexT.init(-1, 0); // Going upwards "^"
        while (true) {
            const res = try visited_dir.getOrPut(F.complexTo64(position, direction));
            if (res.found_existing) {
                p2_sum += 1;
                break;
            }
            const next_pos = position.add(direction);
            if (!F.inBounds(next_pos, rows, cols)) break;

            const row: u16 = @bitCast(next_pos.re);
            const col: u16 = @bitCast(next_pos.im);
            if (mat[row][col] == '#' or (row == i and col == j)) {
                direction = direction.mul(rot_right);
            } else {
                position = next_pos;
            }
        }
    }
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ visited_slice.len, p2_sum });
}
