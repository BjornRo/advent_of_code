const std = @import("std");
const utils = @import("utils.zig");
const Deque = @import("deque.zig").Deque;
const Allocator = std.mem.Allocator;

const Entity = struct {
    items: Deque(i64),
    op: enum { Add, Mul },
    cons: ?i8,
    @"test": i8,
    rtrue: u8,
    rfalse: u8,
    inspect: u32,

    const Self = @This();
    fn throw(self: *Self, modulo: ?i64) ?struct { index: usize, value: i64 } {
        if (self.items.popFront()) |item| {
            self.inspect += 1;
            const result = if (modulo) |value|
                @mod(switch (self.op) {
                    .Add => item + (self.cons orelse item),
                    .Mul => item * (self.cons orelse item),
                }, value)
            else
                @divTrunc(switch (self.op) {
                    .Add => item + (self.cons orelse item),
                    .Mul => item * (self.cons orelse item),
                }, 3);
            return .{
                .index = if (@mod(result, self.@"test") == 0) self.rtrue else self.rfalse,
                .value = result,
            };
        }
        return null;
    }
    fn init(alloc: Allocator, raw_str: []const u8) !Self {
        var new: Self = undefined;
        new.inspect = 0;
        var row_iter = std.mem.splitScalar(u8, raw_str, '\n');
        _ = row_iter.next();
        new.items = try .init(alloc);
        var item_iter = utils.NumberIter(@TypeOf(new.items.buf[0])){ .string = row_iter.next().? };
        while (item_iter.next()) |value| try new.items.pushBack(value);
        const op_row = row_iter.next().?;
        new.op = if (std.mem.containsAtLeastScalar(u8, op_row, 1, '+')) .Add else .Mul;
        new.cons = utils.firstNumber(@TypeOf(new.cons.?), 0, op_row).value;
        new.@"test" = utils.firstNumber(@TypeOf(new.@"test"), 0, row_iter.next().?).value.?;
        new.rtrue = utils.firstNumber(@TypeOf(new.rtrue), 0, row_iter.next().?).value.?;
        new.rfalse = utils.firstNumber(@TypeOf(new.rfalse), 0, row_iter.next().?).value.?;
        return new;
    }
};
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

    const data = try utils.read(alloc, "in/d11.txt");
    defer alloc.free(data);

    std.debug.print("Part 1: {d}\n", .{try solver(alloc, data, false)});
    std.debug.print("Part 2: {d}\n", .{try solver(alloc, data, true)});
}

fn solver(alloc: Allocator, data: []const u8, p2: bool) !usize {
    var monkeys: std.ArrayList(Entity) = .empty;
    defer {
        for (monkeys.items) |m| m.items.deinit();
        monkeys.deinit(alloc);
    }

    var splitIter = std.mem.splitSequence(u8, data, "\n\n");
    while (splitIter.next()) |item| try monkeys.append(alloc, try .init(alloc, item));

    var modulo: ?i64 = null;
    if (p2) {
        modulo = 1;
        for (monkeys.items) |m| modulo.? *= m.@"test";
    }

    for (0..if (p2) 10000 else 20) |_| for (monkeys.items) |*m| while (m.throw(modulo)) |res|
        try monkeys.items[res.index].items.pushBack(res.value);

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
