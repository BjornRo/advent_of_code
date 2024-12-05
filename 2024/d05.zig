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

    var incorrect_updates = std.ArrayList([]const []const u8).init(allocator);
    defer {
        for (incorrect_updates.items) |i| allocator.free(i);
        incorrect_updates.deinit();
    }

    var p1_sum: u32 = 0;
    p1_sum += 0;
    var updates_iter = std.mem.splitSequence(u8, rules_updates.next().?, row_delim);
    while (updates_iter.next()) |update| {
        if (update.len == 0) break;
        var comma_iter = std.mem.splitScalar(u8, update, ',');
        while (comma_iter.next()) |elem| try row_elems.append(elem);

        const slice = row_elems.items;
        for (0..slice.len - 1) |i| {
            const rule = concatVert(allocator, slice[i], slice[i + 1]);
            defer allocator.free(rule);
            if (rules.get(rule) == null) {
                try incorrect_updates.append(try row_elems.toOwnedSlice());
                break;
            }
        } else {
            p1_sum += int(slice[slice.len / 2]);
        }
        row_elems.clearRetainingCapacity();
    }
    myf.printAny(p1_sum);
    myf.printAny(incorrect_updates.items);
}

fn concatVert(alloc: std.mem.Allocator, left: []const u8, right: []const u8) []u8 {
    return std.mem.concat(alloc, u8, &.{ left, "|", right }) catch unreachable;
}

fn int(i: []const u8) u8 {
    return std.fmt.parseInt(u8, i, 10) catch unreachable;
}
