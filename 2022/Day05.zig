const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var da: std.heap.DebugAllocator(.{}) = .init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d05.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    defer alloc.free(result.p1);
    defer alloc.free(result.p2);
    std.debug.print("Part 1: {s}\n", .{result.p1});
    std.debug.print("Part 2: {s}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: []u8, p2: []u8 } {
    var splitIter = std.mem.splitSequence(u8, data, "\n\n");
    const stacks = blk: {
        var rawStacks: std.ArrayList([]const u8) = .empty;
        defer rawStacks.deinit(alloc);
        var stacksIter = std.mem.splitBackwardsScalar(u8, splitIter.next().?, '\n');
        while (stacksIter.next()) |item| try rawStacks.append(alloc, item);

        const stacks1 = try alloc.alloc(std.ArrayList(u8), std.mem.max(u8, rawStacks.items[0]) - '0');
        const stacks2 = try alloc.alloc(std.ArrayList(u8), std.mem.max(u8, rawStacks.items[0]) - '0');
        for (stacks1) |*row| row.* = .empty;
        for (stacks2) |*row| row.* = .empty;

        const rows = rawStacks.items.len;
        const cols = rawStacks.items[0].len;
        for (0..cols) |col| {
            const firstRowCol = rawStacks.items[0][col];
            if (!('0' <= firstRowCol and firstRowCol <= '9')) continue;
            for (1..rows) |row| {
                const elem = rawStacks.items[row][col];
                if ('A' <= elem and elem <= 'Z') {
                    try stacks1[firstRowCol - '0' - 1].append(alloc, elem);
                    try stacks2[firstRowCol - '0' - 1].append(alloc, elem);
                }
            }
        }
        break :blk [2][]std.ArrayList(u8){ stacks1, stacks2 };
    };
    defer {
        for (stacks) |s| {
            for (s) |*stack| stack.*.deinit(alloc);
            alloc.free(s);
        }
    }

    const sequences = blk: {
        const Row = struct {
            count: u8,
            from: u8,
            to: u8,
            fn init(string: []const u8) !@This() {
                var buffer: [3]u8 = undefined;
                var i: usize = 0;
                var iter = std.mem.splitScalar(u8, string, ' ');
                while (iter.next()) |item|
                    if ('0' <= item[0] and item[0] <= '9') {
                        buffer[i] = try std.fmt.parseUnsigned(u8, item, 10);
                        i += 1;
                    };
                return .{ .count = buffer[0], .from = buffer[1] - 1, .to = buffer[2] - 1 };
            }
        };
        var sequences: std.ArrayList(Row) = .empty;
        defer sequences.deinit(alloc);
        var sequencesIter = std.mem.splitScalar(u8, splitIter.next().?, '\n');
        while (sequencesIter.next()) |row| try sequences.append(alloc, try .init(row));

        break :blk try sequences.toOwnedSlice(alloc);
    };
    defer alloc.free(sequences);

    for (sequences) |sequence| {
        for (0..sequence.count) |_| try stacks[0][sequence.to].append(alloc, stacks[0][sequence.from].pop().?);
        const target = stacks[1][sequence.from].items;
        try stacks[1][sequence.to].appendSlice(alloc, target[target.len - sequence.count ..]);
        stacks[1][sequence.from].items.len -= sequence.count;
    }

    const msg0 = try alloc.alloc(u8, stacks[0].len);
    for (stacks[0], 0..) |stack, i| msg0[i] = stack.items[stack.items.len - 1];
    const msg1 = try alloc.alloc(u8, stacks[1].len);
    for (stacks[1], 0..) |stack, i| msg1[i] = stack.items[stack.items.len - 1];
    return .{ .p1 = msg0, .p2 = msg1 };
}
