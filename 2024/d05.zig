const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const expect = std.testing.expect;
const time = std.time;

inline fn int(i: []const u8) u8 {
    return std.fmt.parseInt(u8, i, 10) catch unreachable;
}

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
    var buffer: [91_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup
    const in_attributes = try myf.getDelimType(input);
    const row_delim = if (in_attributes.delim == .CRLF) "\r\n" else "\n";

    var rules_updates = std.mem.tokenizeSequence(u8, input, if (in_attributes.delim == .CRLF) "\r\n\r\n" else "\n\n");

    var rules = std.StringHashMap(bool).init(allocator);
    defer rules.deinit();
    var rules_iter = std.mem.tokenizeSequence(u8, rules_updates.next().?, row_delim);
    while (rules_iter.next()) |rule| try rules.put(rule, true);

    var row_elems = std.ArrayList([]const u8).init(allocator);
    defer row_elems.deinit();

    var p1_sum: u32 = 0;
    var p2_sum: u32 = 0;
    var updates_iter = std.mem.tokenizeSequence(u8, rules_updates.next().?, row_delim);
    while (updates_iter.next()) |update| {
        var comma_iter = std.mem.splitScalar(u8, update, ',');
        while (comma_iter.next()) |elem| try row_elems.append(elem);
        defer row_elems.clearRetainingCapacity();

        const slice = row_elems.items;
        const half_slice = slice.len / 2;
        for (0..slice.len - 1) |i| {
            const left = slice[i];
            const right = slice[i + 1];
            if (rules.get(&.{ left[0], left[1], '|', right[0], right[1] }) == null) {
                for (0..half_slice + 1) |j| {
                    for (j..slice.len) |k| {
                        const bleft = slice[j];
                        const bright = slice[k];
                        if (rules.get(&.{ bleft[0], bleft[1], '|', bright[0], bright[1] }) != null) continue;
                        slice[j] = bright;
                        slice[k] = bleft;
                    }
                }
                p2_sum += int(slice[half_slice]);
                break;
            }
        } else {
            p1_sum += int(slice[half_slice]);
        }
    }
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}
