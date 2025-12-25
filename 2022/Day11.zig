const std = @import("std");
const utils = @import("utils.zig");
const Deque = @import("deque.zig").Deque;
const Allocator = std.mem.Allocator;

const Entity = struct {
    items: Deque(i64),
    op: enum { Add, Mul },
    cons: ?i64,
    @"test": i64,
    rtrue: usize,
    rfalse: usize,
    inspect: usize,
    factor: i64,

    const Self = @This();
    fn throw(self: *Self) ?struct { index: usize, value: i64 } {
        if (self.items.popFront()) |item| {
            self.inspect += 1;
            const result = @divTrunc(switch (self.op) {
                .Add => item + (self.cons orelse item),
                .Mul => item * (self.cons orelse item),
            }, self.factor);
            return .{
                .index = if (@rem(result, self.@"test") == 0) self.rtrue else self.rfalse,
                .value = result,
            };
        }
        return null;
    }
    fn init(alloc: Allocator, raw_str: []const u8, factor: i64) !*Self {
        var new = try alloc.create(Self);
        new.inspect = 0;
        new.factor = factor;
        new.items = try .init(alloc);
        var row_iter = std.mem.splitScalar(u8, raw_str, '\n');
        _ = row_iter.next();
        var item_iter = utils.NumberIter(i64){ .string = row_iter.next().? };
        while (item_iter.next()) |value| try new.items.pushBack(value);
        const op_row = row_iter.next().?;
        new.op = if (std.mem.containsAtLeastScalar(u8, op_row, 1, '+')) .Add else .Mul;
        new.cons = if (utils.firstNumber(i64, 0, op_row)) |s| s.value else null;
        new.@"test" = utils.firstNumber(i64, 0, row_iter.next().?).?.value;
        new.rtrue = utils.firstNumber(usize, 0, row_iter.next().?).?.value;
        new.rfalse = utils.firstNumber(usize, 0, row_iter.next().?).?.value;
        return new;
    }
    fn deinit(self: *Self, alloc: Allocator) void {
        self.items.deinit();
        alloc.destroy(self);
    }
};

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d11.txt");
    defer alloc.free(data);

    std.debug.print("Part 1: {d}\n", .{try solve_p1(alloc, data)});
    std.debug.print("Part 2: {d}\n", .{1});
}

fn solve_p1(alloc: Allocator, data: []const u8) !usize {
    var monkeys: std.ArrayList(*Entity) = .empty;
    defer {
        for (monkeys.items) |m| m.deinit(alloc);
        monkeys.deinit(alloc);
    }

    var splitIter = std.mem.splitSequence(u8, data, "\n\n");
    while (splitIter.next()) |item| {
        try monkeys.append(alloc, try .init(alloc, item, 3));
    }

    for (0..20) |_| {
        for (monkeys.items) |m|
            while (m.throw()) |res|
                try monkeys.items[res.index].items.pushBack(res.value);
    }

    var max1: usize = 0;
    var max2: usize = 0;
    for (monkeys.items) |m| {
        if (m.inspect > max1) {
            max2 = max1;
            max1 = m.inspect;
        } else if (m.inspect > max2) {
            max2 = m.inspect;
        }
    }
    return max1 * max2;
}
