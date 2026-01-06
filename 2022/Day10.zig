const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const WIDTH = 40;
const HEIGHT = 6;
const CRT = [HEIGHT][WIDTH]u8;
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const alloc, const is_debug = switch (@import("builtin").mode) {
        .Debug => .{ debug_allocator.allocator(), true },
        else => .{ std.heap.smp_allocator, false },
    };
    const start = std.time.microTimestamp();
    defer {
        std.debug.print("Time: {any}s\n", .{@as(f64, @floatFromInt(std.time.microTimestamp() - start)) / 1000_000});
        if (is_debug) _ = debug_allocator.deinit();
    }

    const data = try utils.read(alloc, "in/d10.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2:\n", .{});
    for (result.p2) |row| std.debug.print("{s}\n", .{row});
}
fn solve(alloc: Allocator, data: []const u8) !struct { p1: isize, p2: CRT } {
    var rows = std.mem.splitScalar(u8, data, '\n');
    var program: std.ArrayList(?isize) = .empty;
    defer program.deinit(alloc);
    while (rows.next()) |item| try program.append(alloc, if (utils.firstNumber(isize, 0, item)) |v| v.value else null);

    var __part1: [7]isize = .{ -1, 220, 180, 140, 100, 60, 20 };
    var p1cycles: std.ArrayList(isize) = .fromOwnedSlice(&__part1);
    var buf: [WIDTH * HEIGHT]u8 = undefined;
    var screen: std.ArrayList(u8) = .initBuffer(&buf);

    var total_p1: isize = 0;
    var cycles: isize = 0;
    var reg: isize = 1;
    while (cycles < WIDTH * HEIGHT) for (program.items) |op| {
        screen.appendAssumeCapacity(if (@abs(@mod(cycles, WIDTH) - reg) <= 1) '#' else ' ');
        cycles += 1;
        if (cycles == p1cycles.getLast()) total_p1 += reg * p1cycles.pop().?;
        if (op) |value| {
            screen.appendAssumeCapacity(if (@abs(@mod(cycles, WIDTH) - reg) <= 1) '#' else ' ');
            cycles += 1;
            if (cycles == p1cycles.getLast()) total_p1 += reg * p1cycles.pop().?;
            reg += value;
        }
    };
    return .{ .p1 = total_p1, .p2 = @as(CRT, @bitCast(buf)) };
}
