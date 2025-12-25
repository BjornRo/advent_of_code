const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const WIDTH = 40;
const HEIGHT = 6;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d10.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    defer alloc.free(result.p2);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2:\n", .{});
    for (result.p2) |row| std.debug.print("{s}\n", .{row});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: isize, p2: *[HEIGHT][WIDTH]u8 } {
    var splitIter = std.mem.splitScalar(u8, data, '\n');

    var program: std.ArrayList(?isize) = .empty;
    defer program.deinit(alloc);

    while (splitIter.next()) |item| {
        var rowIter = std.mem.splitScalar(u8, item, ' ');
        if (rowIter.next().?[0] == 'n')
            try program.append(alloc, null)
        else
            try program.append(alloc, try std.fmt.parseInt(isize, rowIter.next().?, 10));
    }

    var part1: [7]isize = .{ -1, 220, 180, 140, 100, 60, 20 };
    var p1cycles: std.ArrayList(isize) = .fromOwnedSlice(&part1);
    var crt: std.ArrayList(u8) = try .initCapacity(alloc, WIDTH * HEIGHT);
    defer crt.deinit(alloc);

    var total_p1: isize = 0;

    var cycles: isize = 0;
    var reg: isize = 1;
    while (cycles < WIDTH * HEIGHT) {
        for (program.items) |op| {
            crt.appendAssumeCapacity(if (@abs(@mod(cycles, WIDTH) - reg) <= 1) '#' else ' ');
            cycles += 1;
            if (cycles == p1cycles.items[p1cycles.items.len - 1]) {
                if (p1cycles.pop()) |res| total_p1 += reg * res;
            }
            if (op) |value| {
                crt.appendAssumeCapacity(if (@abs(@mod(cycles, WIDTH) - reg) <= 1) '#' else ' ');
                cycles += 1;
                if (cycles == p1cycles.items[p1cycles.items.len - 1]) {
                    if (p1cycles.pop()) |res| total_p1 += reg * res;
                }
                reg += value;
            }
        }
    }
    return .{ .p1 = total_p1, .p2 = @as(*[HEIGHT][WIDTH]u8, @ptrCast(try crt.toOwnedSlice(alloc))) };
}
