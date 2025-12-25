const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const Entity = struct {
    items: std.ArrayList(i32),
    op: enum { Add, Mul },
    cons: ?i32,
    @"test": i32,
    rtrue: usize,
    rfalse: usize,

    const Self = @This();
    fn init(alloc: Allocator, raw_str: []const u8) !*Self {
        var new = try alloc.create(Self);
        new.items = .empty;

        var row_iter = std.mem.splitScalar(u8, raw_str, '\n');
        _ = row_iter.next();
        var item_iter = NumberIter{ .string = row_iter.next().? };
        while (try item_iter.next()) |value| try new.items.append(alloc, value);

        const op_row = row_iter.next().?;
        new.op = if (std.mem.containsAtLeastScalar(u8, op_row, 1, '+')) .Add else .Mul;
        var op_iter = NumberIter{ .string = op_row };
        new.cons = try op_iter.next();
        var test_iter = NumberIter{ .string = row_iter.next().? };
        new.@"test" = (try test_iter.next()).?;
        var true_iter = NumberIter{ .string = row_iter.next().? };
        new.rtrue = @intCast((try true_iter.next()).?);
        var false_iter = NumberIter{ .string = row_iter.next().? };
        new.rfalse = @intCast((try false_iter.next()).?);

        std.debug.print("{any}\n", .{new});
        return new;
    }
    fn throw(self: *Self) ?struct { index: usize, value: i32 } {
        if (self.items.pop()) |item| {
            const result = switch (self.op) {
                .Add => item + (self.cons orelse item),
                .Mul => item * (self.cons orelse item),
            } / 3;
            return .{
                .index = if (result % self.@"test" == 0) self.rtrue else self.rfalse,
                .value = result,
            };
        }
        return null;
    }
    fn deinit(self: *Self, alloc: Allocator) void {
        @constCast(self).items.deinit(alloc);
        alloc.destroy(self);
    }
};

const NumberIter = struct {
    index: usize = 0,
    string: []const u8,
    const Self = @This();
    fn next(self: *Self) !?i32 {
        var start = self.index;
        while (start < self.string.len) : (start += 1)
            if ('0' <= self.string[start] and self.string[start] <= '9') break;
        if (start >= self.string.len) return null;
        var end = start + 1;
        while (end < self.string.len) : (end += 1)
            if (!('0' <= self.string[end] and self.string[end] <= '9')) break;
        self.index = end;
        return try std.fmt.parseInt(i32, self.string[start..end], 10);
    }
};

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d11t.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var monkeys: std.ArrayList(*Entity) = .empty;
    defer {
        for (monkeys.items) |m| m.deinit(alloc);
        monkeys.deinit(alloc);
    }

    var splitIter = std.mem.splitSequence(u8, data, "\n\n");
    while (splitIter.next()) |item| {
        try monkeys.append(alloc, try .init(alloc, item));
    }

    return .{ .p1 = 1, .p2 = 2 };
}
