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
        fn safe_row(row: []T) bool {
            var prev = row[0];
            var curr = row[1];
            if (prev == curr or @abs(prev - curr) > MAX_DIFF) return false;
            const increasing = prev < curr;

            for (1..row.len) |i| {
                curr = row[i];
                if (!safe(prev, curr, increasing, MAX_DIFF)) return false;
                prev = curr;
            }
            return true;
        }
    };

    var p1_sum: T = 0;
    var p2_sum: T = 0;

    const delim = if (try myf.getDelimType(input) == .CRLF) "\r\n" else "\n";
    var input_iter = std.mem.splitSequence(u8, input, delim);
    while (input_iter.next()) |row_str| {
        if (row_str.len == 0) continue;
        var row = std.ArrayList(T).init(allocator);
        defer row.deinit();

        var row_iter = std.mem.splitScalar(u8, row_str, ' ');
        while (row_iter.next()) |scalar| try row.append(try std.fmt.parseInt(T, scalar, 10));

        if (S.safe_row(row.items)) {
            p1_sum += 1;
            p2_sum += 1;
            continue;
        }
        const slice = row.items;
        for (0..slice.len) |i| {
            var masked_row = std.ArrayList(T).init(allocator);
            defer masked_row.deinit();
            for (0..slice.len) |j| {
                if (i == j) continue;
                try masked_row.append(slice[j]);
            }
            if (S.safe_row(masked_row.items)) {
                p2_sum += 1;
                break;
            }
        }
    }
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}
