const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const List = std.ArrayList(ValueList);
const ValueList = union(enum) {
    value: u8,
    list: List,

    const Self = @This();
    fn deinit(self: *Self, alloc: Allocator) void {
        if (self.* == .value) return;
        for (self.list.items) |*item| item.deinit(alloc);
        self.list.deinit(alloc);
    }
    fn parse(alloc: Allocator, s: []const u8) !Self {
        var index: usize = 0;
        return __parse(alloc, s, &index);
    }
    fn __parse(alloc: Allocator, s: []const u8, i: *usize) !Self {
        while (i.* < s.len and s[i.*] == ',') : (i.* += 1) {}
        if (s[i.*] == '[') {
            i.* += 1;
            var new: Self = .{ .list = .empty };
            while (i.* < s.len and s[i.*] != ']') {
                try new.list.append(alloc, try __parse(alloc, s, i));
                while (i.* < s.len and (s[i.*] == ',')) : (i.* += 1) {}
            }
            i.* += 1;
            return new;
        }
        const start = i.*;
        while (i.* < s.len and s[i.*] >= '0' and s[i.*] <= '9') : (i.* += 1) {}
        const num = std.fmt.parseInt(u8, s[start..i.*], 10) catch unreachable;
        return Self{ .value = num };
    }
    fn print(self: Self, depth: usize) void {
        if (self == .value) std.debug.print("{}", .{self.value}) else {
            const items = self.list.items;
            std.debug.print("[", .{});
            for (items, 0..) |*item, i| {
                print(item, depth + 1);
                if (i != items.len - 1) std.debug.print(",", .{});
            }
            std.debug.print("]", .{});
        }
        if (depth == 0) std.debug.print("\n", .{});
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

    const data = try utils.read(alloc, "in/d13.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}
fn comparer(alloc: Allocator, left: ValueList, right: ValueList) !?bool {
    if (left == .value and right == .value) {
        if (left.value > right.value) return false;
        if (left.value < right.value) return true;
        return null;
    } else if (left == .list and right == .list) {
        const l = left.list.items;
        const r = right.list.items;
        for (0..@max(l.len, r.len)) |i| {
            if (i >= l.len) return true;
            if (i >= r.len) return false;
            if (try comparer(alloc, l[i], r[i])) |res| return res;
        }
        return null;
    } else if (left == .value) {
        var vl = ValueList{ .list = .empty };
        try vl.list.append(alloc, left);
        defer vl.deinit(alloc);
        return try comparer(alloc, vl, right);
    }
    var vl = ValueList{ .list = .empty };
    try vl.list.append(alloc, right);
    defer vl.deinit(alloc);
    return try comparer(alloc, left, vl);
}
fn cmp(alloc: Allocator, left: ValueList, right: ValueList) bool {
    return (comparer(alloc, left, right) catch unreachable).?;
}
fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var list: std.ArrayList(ValueList) = .empty;
    defer {
        for (list.items) |*l| l.deinit(alloc);
        list.deinit(alloc);
    }
    var total_p1: usize = 0;
    {
        var i: usize = 1;
        var splitIter = std.mem.splitSequence(u8, data, "\n\n");
        while (splitIter.next()) |item| : (i += 1) {
            var rowIter = std.mem.splitScalar(u8, item, '\n');
            try list.append(alloc, try ValueList.parse(alloc, rowIter.next().?));
            try list.append(alloc, try ValueList.parse(alloc, rowIter.next().?));
            if ((try comparer(alloc, list.items[list.items.len - 2], list.getLast())).?) total_p1 += i;
        }
        try list.append(alloc, try ValueList.parse(alloc, "[[2]]"));
        try list.append(alloc, try ValueList.parse(alloc, "[[6]]"));
        std.mem.sortUnstable(ValueList, list.items, alloc, cmp);
    }
    var key_p2: usize = 1;
    for (list.items, 1..) |*v, i| {
        const l = v.list.items;
        if (l.len == 1 and l[0] == .list) {
            const r = l[0].list.items;
            if (r.len == 1 and r[0] == .value and (r[0].value == 2 or r[0].value == 6)) key_p2 *= i;
        }
    }
    return .{ .p1 = total_p1, .p2 = key_p2 };
}
