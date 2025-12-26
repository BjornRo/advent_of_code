const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const List = std.ArrayList(ValueList);
const ValueList = union(enum) {
    value: u8,
    list: *List,

    const Self = @This();
    fn initList(alloc: Allocator) !*List {
        const list = try alloc.create(List);
        list.* = .empty;
        return list;
    }
    fn deinit(self: *Self, alloc: Allocator) void {
        switch (self.*) {
            .value => {},
            .list => |l| {
                for (l.items) |*item| item.deinit(alloc);
                l.deinit(alloc);
                alloc.destroy(l);
            },
        }
    }
    fn parse(alloc: Allocator, s: []const u8, i: *usize) !Self {
        while (i.* < s.len and s[i.*] == ',') : (i.* += 1) {}
        if (s[i.*] == '[') {
            i.* += 1;
            var inner_list = try Self.initList(alloc);
            while (i.* < s.len and s[i.*] != ']') {
                try inner_list.append(alloc, try parse(alloc, s, i));
                while (i.* < s.len and (s[i.*] == ',')) : (i.* += 1) {}
            }
            i.* += 1;
            return Self{ .list = inner_list };
        }
        const start = i.*;
        while (i.* < s.len and s[i.*] >= '0' and s[i.*] <= '9') : (i.* += 1) {}
        const num = std.fmt.parseInt(u8, s[start..i.*], 10) catch unreachable;
        return Self{ .value = num };
    }
    fn print(self: *Self, depth: usize) void {
        if (self.* == .value) std.debug.print("{}", .{self.value}) else {
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
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d13.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}
fn comparer(alloc: Allocator, left: *ValueList, right: *ValueList) !?bool {
    if (left.* == .value and right.* == .value) {
        if (left.value > right.value) return false;
        if (left.value < right.value) return true;
        return null;
    } else if (left.* == .list and right.* == .list) {
        const l = left.list.items;
        const r = right.list.items;
        for (0..@max(l.len, r.len)) |i| {
            if (i >= l.len) return true;
            if (i >= r.len) return false;
            if (try comparer(alloc, &l[i], &r[i])) |res| return res;
        }
        return null;
    } else if (left.* == .value) {
        const list = try ValueList.initList(alloc);
        try list.append(alloc, left.*);
        var vl = ValueList{ .list = list };
        defer vl.deinit(alloc);
        return try comparer(alloc, &vl, right);
    } else {
        const list = try ValueList.initList(alloc);
        try list.append(alloc, right.*);
        var vl = ValueList{ .list = list };
        defer vl.deinit(alloc);
        return try comparer(alloc, left, &vl);
    }
}
fn bubbleSort(alloc: Allocator, arr: []ValueList) !void {
    const n = arr.len;
    for (0..n) |i| for (0..n - i - 1) |j| {
        const a = &arr[j];
        const b = &arr[j + 1];
        if (try comparer(alloc, a, b)) |res| if (!res) std.mem.swap(ValueList, a, b);
    };
}
fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var list: std.ArrayList(ValueList) = .empty;
    defer {
        for (list.items) |*l| l.deinit(alloc);
        list.deinit(alloc);
    }

    var splitIter = std.mem.splitSequence(u8, data, "\n\n");
    var total_p1: usize = 0;
    var i: usize = 1;
    while (splitIter.next()) |item| : (i += 1) {
        var rowIter = std.mem.splitScalar(u8, item, '\n');
        var index: usize = 0;
        var first = try ValueList.parse(alloc, rowIter.next().?, &index);
        index = 0;
        var second = try ValueList.parse(alloc, rowIter.next().?, &index);
        if ((try comparer(alloc, &first, &second)).?) total_p1 += i;

        try list.append(alloc, first);
        try list.append(alloc, second);
    }
    var index: usize = 0;
    try list.append(alloc, try ValueList.parse(alloc, "[[2]]", &index));
    index = 0;
    try list.append(alloc, try ValueList.parse(alloc, "[[6]]", &index));

    try bubbleSort(alloc, list.items);

    var key_p2: usize = 1;
    for (list.items, 1..) |*v, j| {
        const l = v.list.items;
        if (l.len == 1 and l[0] == .list) {
            const r = l[0].list.items;
            if (r.len == 1 and r[0] == .value and (r[0].value == 2 or r[0].value == 6))
                key_p2 *= j;
        }
    }
    return .{ .p1 = total_p1, .p2 = key_p2 };
}
