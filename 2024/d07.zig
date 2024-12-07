const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = myf.printAny;
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

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input = @embedFile("in/d07.txt");
    // End setup

    var mop = std.ArrayList(u8).init(allocator);
    defer mop.deinit();
    var aop = std.ArrayList(u8).init(allocator);
    defer aop.deinit();
    var values = std.ArrayList(u64).init(allocator);
    defer values.deinit();

    var p1_sum: u128 = 0;
    p1_sum += 0;

    const input_attributes = try myf.getDelimType(input);
    var in_iter = std.mem.tokenizeSequence(u8, input, if (input_attributes.delim == .CRLF) "\r\n" else "\n");
    while (in_iter.next()) |row| {
        defer aop.clearRetainingCapacity();
        defer mop.clearRetainingCapacity();
        defer values.clearRetainingCapacity();

        const colon = std.mem.indexOf(u8, row, ":").?;
        const left_sum = try std.fmt.parseInt(u64, row[0..colon], 10);
        var value_iter = std.mem.tokenizeScalar(u8, row[colon + 1 ..], ' ');
        while (value_iter.next()) |val| try values.append(try std.fmt.parseInt(u64, val, 10));

        const slice = values.items;

        var early_break = false;
        p1_sum += recurse(0, @intCast(slice.len), left_sum, 0, &slice, &early_break);
    }
    print(p1_sum);
}

fn recurse(idx: u8, max_idx: u8, target_sum: u64, count: u64, values: *const []u64, early_break: *bool) u64 {
    if (early_break.*) return 0;
    if (idx == max_idx) {
        if (target_sum == count) {
            return count;
        }
        return 0;
    }
    const rmul = recurse(idx + 1, max_idx, target_sum, values.*[idx] * count, values, early_break);
    const radd = recurse(idx + 1, max_idx, target_sum, values.*[idx] + count, values, early_break);
    if (rmul == target_sum) return {
        early_break.* = true;
        return rmul;
    };
    if (radd == target_sum) return {
        early_break.* = true;
        return radd;
    };
    return 0;
}
