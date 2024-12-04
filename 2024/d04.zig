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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    std.debug.print("input len: {d}\n\n", .{input.len});
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
    var p1_sum: u64 = 0;
    inline for (.{ "XMAS", "SAMX" }) |word| {
        for (0..rows - 3) |i| {
            for (0..cols - 3) |j| {
                if (std.mem.eql(u8, mat[i][j .. j + 4], word)) p1_sum += 1;

                const vert: [4]u8 = .{
                    mat[i][j],
                    mat[i + 1][j],
                    mat[i + 2][j],
                    mat[i + 3][j],
                };
                if (std.mem.eql(u8, &vert, word)) p1_sum += 1;
                const diag: [4]u8 = .{
                    mat[i][j],
                    mat[i + 1][j + 1],
                    mat[i + 2][j + 2],
                    mat[i + 3][j + 3],
                };
                if (std.mem.eql(u8, &diag, word)) p1_sum += 1;
                const diag2: [4]u8 = .{
                    mat[i][j + 3],
                    mat[i + 1][j + 2],
                    mat[i + 2][j + 1],
                    mat[i + 3][j + 0],
                };
                if (std.mem.eql(u8, &diag2, word)) p1_sum += 1;
            }
            for (cols - 3..cols) |k| {
                const vert: [4]u8 = .{
                    mat[i][k],
                    mat[i + 1][k],
                    mat[i + 2][k],
                    mat[i + 3][k],
                };
                if (std.mem.eql(u8, &vert, word)) p1_sum += 1;
            }
        }
    }
    for (rows - 3..rows) |i| {
        for (0..cols - 3) |j| {
            inline for (.{ "XMAS", "SAMX" }) |word| {
                // Cannot figure out how to fix runtime/comptime slices/arrays.
                if (std.mem.eql(u8, mat[i][j .. j + 4], word)) p1_sum += 1;
            }
        }
    }
    myf.printAny(p1_sum);

    var p2_sum: u64 = 0;
    for (0..rows - 2) |i| {
        for (0..cols - 2) |j| {
            var x: u8 = 0;
            inline for (.{ "MAS", "SAM" }) |word| {
                const diag: [3]u8 = .{
                    mat[i][j],
                    mat[i + 1][j + 1],
                    mat[i + 2][j + 2],
                };
                if (std.mem.eql(u8, &diag, word)) x += 1;
                const diag2: [3]u8 = .{
                    mat[i][j + 2],
                    mat[i + 1][j + 1],
                    mat[i + 2][j],
                };
                if (std.mem.eql(u8, &diag2, word)) x += 1;
            }
            if (x == 2) p2_sum += 1;
        }
    }
    myf.printAny(p2_sum);
}
