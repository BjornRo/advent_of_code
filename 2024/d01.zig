const std = @import("std");
const myf = @import("myfunc.zig");
const expect = std.testing.expect;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();

    const filename = try myf.getFirstAppArg(allocator);
    defer allocator.free(filename);

    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    defer allocator.free(target_file);

    const input = try myf.readFile(allocator, target_file);
    defer allocator.free(input);
    // End setup

    std.debug.print("{s}\n", .{input});
}
