const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

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
    var buffer: [25_500]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    var values = std.ArrayList(u64).init(allocator);
    defer values.deinit();

    var p1_sum: u64 = 0;
    p1_sum += 0;
    var p2_sum: u64 = 0;
    p2_sum += 0;

    const input_attributes = try myf.getDelimType(input);
    var in_iter = std.mem.tokenizeSequence(u8, input, if (input_attributes.delim == .CRLF) "\r\n" else "\n");
    while (in_iter.next()) |row| {
        defer values.clearRetainingCapacity();

        const colon = std.mem.indexOf(u8, row, ":").?;
        const left_sum = try std.fmt.parseInt(u64, row[0..colon], 10);
        var value_iter = std.mem.tokenizeScalar(u8, row[colon + 1 ..], ' ');
        while (value_iter.next()) |val| try values.append(try std.fmt.parseInt(u64, val, 10));

        const slice = values.items;

        var early_break = false;
        const res = recurse(1, @intCast(slice.len), left_sum, slice[0], &slice, &early_break);
        if (res != 0) {
            p1_sum += res;
        }
        early_break = false;
        const res2 = recurseConcat(1, @intCast(slice.len), left_sum, slice[0], &slice, &early_break);
        if (res2 != 0) {
            p2_sum += res2;
        }
    }
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}

fn recurseConcat(idx: u8, max_idx: u8, target_sum: u64, count: u64, values: *const []u64, early_break: *bool) u64 {
    if (early_break.* or target_sum < count) return 0;
    if (idx == max_idx) {
        if (target_sum == count) {
            early_break.* = true;
            return count;
        }
        return 0;
    }
    const next_idx = idx + 1;

    var res = recurseConcat(next_idx, max_idx, target_sum, count + values.*[idx], values, early_break);
    if (res == target_sum) return res;
    res = recurseConcat(next_idx, max_idx, target_sum, count * values.*[idx], values, early_break);
    if (res == target_sum) return res;

    var buf: [15]u8 = undefined;
    const concat_num = std.fmt.parseInt(@TypeOf(count), std.fmt.bufPrint(&buf, "{}{}", .{ count, values.*[idx] }) catch unreachable, 10) catch unreachable;
    res = recurseConcat(next_idx, max_idx, target_sum, concat_num, values, early_break);
    if (res == target_sum) return res;
    return 0;
}

fn recurse(idx: u8, max_idx: u8, target_sum: u64, count: u64, values: *const []u64, early_break: *bool) u64 {
    if (early_break.* or target_sum < count) return 0;
    if (idx == max_idx) {
        if (target_sum == count) {
            early_break.* = true;
            return count;
        }
        return 0;
    }
    const next_idx = idx + 1;
    var res = recurse(next_idx, max_idx, target_sum, count * values.*[idx], values, early_break);
    if (res == target_sum) return res;
    res = recurse(next_idx, max_idx, target_sum, count + values.*[idx], values, early_break);
    if (res == target_sum) return res;
    return 0;
}
