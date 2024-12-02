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

    const filename = try myf.getFirstAppArg(allocator);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup
    const T = i32;
    const MAX_DIFF = 3;

    const S = struct {
        inline fn safe(a: T, b: T, increasing: bool, diff: T) bool {
            if (@abs(a - b) <= diff) {
                if (increasing) {
                    if (a < b) return true;
                } else {
                    if (a > b) return true;
                }
            }
            return false;
        }
    };

    var p1_sum: T = 0;

    const delim = if (try myf.getDelimType(input) == .CRLF) "\r\n" else "\n";
    var input_iter = std.mem.splitSequence(u8, input, delim);
    while (input_iter.next()) |row| {
        if (row.len == 0) continue;

        var row_iter = std.mem.splitScalar(u8, row, ' ');
        var prev = try std.fmt.parseInt(T, row_iter.next().?, 10);
        var curr = try std.fmt.parseInt(T, row_iter.next().?, 10);
        if (prev == curr or @abs(prev - curr) > MAX_DIFF) continue;
        const increasing = prev < curr;
        prev = curr;
        while (row_iter.next()) |next_scalar| {
            curr = try std.fmt.parseInt(T, next_scalar, 10);
            if (!S.safe(prev, curr, increasing, MAX_DIFF)) break;
            prev = curr;
        } else {
            p1_sum += 1;
        }
    }
    try writer.print("{d}\n", .{p1_sum});
}
