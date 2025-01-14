const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Allocator = std.mem.Allocator;

const Range = struct { start: u32, end: u32 };

fn password_validation(password: []const u8) !?[2]bool {
    var two_adjacent_p1 = false;
    var two_adjacent_p2 = false;
    var count_adjacent: usize = 0;
    for (0..5) |i| {
        const left_digit = password[i];
        const right_digit = password[i + 1];
        if (left_digit == right_digit) {
            two_adjacent_p1 = true;
            count_adjacent += 1;
        } else if (count_adjacent == 1) {
            two_adjacent_p2 = true;
        } else {
            count_adjacent = 0;
        }
        if (left_digit > right_digit) return null;
    }
    if (count_adjacent == 1) two_adjacent_p2 = true;
    return .{ two_adjacent_p1, two_adjacent_p2 };
}

fn solver(range: Range) ![2]u32 {
    var p1_sum: u32 = 0;
    var p2_sum: u32 = 0;
    for (range.start..range.end + 1) |pwd| {
        var buf: [6]u8 = undefined;
        _ = try std.fmt.bufPrint(&buf, "{d}", .{pwd});
        if (try password_validation(&buf)) |result| {
            const p1, const p2 = result;
            if (p1) {
                p1_sum += 1;
                if (p2) p2_sum += 1;
            }
        }
    }
    return .{ p1_sum, p2_sum };
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [500]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    const range: Range = blk: {
        var iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\r\n"), '-');
        const raw_start = iter.next().?;
        var str_start: [6]u8 = undefined;
        for (0..5) |i| {
            str_start[i] = raw_start[i];
            if (raw_start[i] > raw_start[i + 1]) {
                for (i + 1..raw_start.len) |j| str_start[j] = raw_start[i];
                break;
            }
        }

        var str_end: [6]u8 = .{'0'} ** 6;
        str_end[0] = iter.next().?[0];

        const range_start = try std.fmt.parseInt(u32, &str_start, 10);
        const range_end = try std.fmt.parseInt(u32, &str_end, 10) - 1;
        break :blk .{ .start = range_start, .end = range_end };
    };

    const p1, const p2 = try solver(range);
    std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ p1, p2 });
}
