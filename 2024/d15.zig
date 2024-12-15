const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
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
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input = @embedFile("in/d06t.txt");
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    // std.debug.print("{s}\n", .{input});
}

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d15t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const dim: u8 = @intCast(input_attributes.row_len);

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var grid_movement_iter = std.mem.tokenizeSequence(u8, input, double_delim);

    const matrix = try allocator.alloc([]const u8, dim);
    defer allocator.free(matrix);
    var grid_iter = std.mem.tokenizeSequence(u8, grid_movement_iter.next().?, input_attributes.delim);

    var start_row: u8 = 0;
    var start_col: u8 = 0;
    for (matrix, 0..) |*row, i| {
        row.* = grid_iter.next().?;
        if (std.mem.indexOfScalar(u8, row.*, '@')) |j| {
            start_row = @intCast(i);
            start_col = @intCast(j);
        }
    }
    std.testing.expect(start_row != 0 and start_col != 0);

    const movement = grid_movement_iter.next().?;
    myf.printMatStr(matrix);
    prints(movement);
}
