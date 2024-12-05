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
    var buffer: [91_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    std.debug.print("Input size: {d}\n\n", .{input.len});
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup
    const in_attributes = try myf.getDelimType(input);
    const row_delim = if (in_attributes.delim == .CRLF) "\r\n" else "\n";

    var rules_updates = std.mem.splitSequence(u8, input, if (in_attributes.delim == .CRLF) "\r\n\r\n" else "\n\n");

    // Rules are in shape of "VAL0|VAL1", simply just do a lookup and ignore value
    // We can swap order of VAL0 and VAL1 to see if they violate anything
    var rules = std.StringHashMap(bool).init(allocator);
    defer rules.deinit();
    var rules_iter = std.mem.splitSequence(u8, rules_updates.next().?, row_delim);
    while (rules_iter.next()) |rule| try rules.put(rule, true);

    var row_elems = std.ArrayList([]const u8).init(allocator);
    defer row_elems.deinit();

    var p1_sum: u32 = 0;
    var p2_sum: u32 = 0;
    var updates_iter = std.mem.splitSequence(u8, rules_updates.next().?, row_delim);
    while (updates_iter.next()) |update| {
        if (update.len == 0) break;
        var comma_iter = std.mem.splitScalar(u8, update, ',');
        while (comma_iter.next()) |elem| try row_elems.append(elem);

        const slice = row_elems.items;
        const half_slice = slice.len / 2;
        for (0..slice.len - 1) |i| {
            const rule = concatVert(allocator, slice[i], slice[i + 1]);
            defer allocator.free(rule);
            if (rules.get(rule) == null) {
                for (0..half_slice + 1) |j| {
                    for (j..slice.len) |k| {
                        const brule = concatVert(allocator, slice[j], slice[k]);
                        defer allocator.free(brule);
                        if (rules.get(brule) != null) continue;
                        const tmp = slice[j];
                        slice[j] = slice[k];
                        slice[k] = tmp;
                    }
                }
                p2_sum += int(slice[half_slice]);
                break;
            }
        } else {
            p1_sum += int(slice[half_slice]);
        }
        row_elems.clearRetainingCapacity();
    }
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}

fn concatVert(alloc: std.mem.Allocator, left: []const u8, right: []const u8) []u8 {
    return std.mem.concat(alloc, u8, &.{ left, "|", right }) catch unreachable;
}

fn int(i: []const u8) u8 {
    return std.fmt.parseInt(u8, i, 10) catch unreachable;
}
