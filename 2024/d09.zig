const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const Tag = packed struct { id: u16 };

const Block = struct {
    available: u8,
    count: u8,
    elems: [9]u16,
    const Self = @This();
    fn initNull(available: u8) Self {
        return .{ .count = 0, .elems = undefined, .available = available };
    }
    fn initFile(size: u8, id: u16) Self {
        var s = Self{ .count = size, .elems = undefined, .available = 0 };
        for (0..size) |i| s.elems[i] = id;
        return s;
    }
    fn removeSlice(self: *Self) []u16 {
        self.available = self.count;
        defer self.count = 0;
        return self.elems[0..self.count];
    }
    fn addSlice(self: *Self, slice: []u16) void {
        const len: u8 = @intCast(slice.len);
        @memcpy(self.elems[self.count .. self.count + len], slice);
        self.available -= len;
        self.count += len;
    }
};

inline fn part1(slice: []?Tag) u64 {
    var left: u64 = 0;
    var right: u64 = slice.len - 1;
    while (true) {
        while (slice[right] == null) right -= 1;
        while (slice[left] != null) left += 1;
        if (left >= right) break;

        const tmp = slice[left];
        slice[left] = slice[right];
        slice[right] = tmp;
    }

    var p1_sum: u64 = 0;
    for (slice, 0..) |e, i| {
        if (e) |v| p1_sum += i * v.id;
    }
    return p1_sum;
}

inline fn part2(slice: []Block) u64 {
    const j = slice.len;
    for (1..j) |i| {
        const rev = j - i;
        var rblock = &slice[rev];
        if (rblock.count == 0) continue;
        for (0..rev) |k| {
            var lblock = &slice[k];
            if (lblock.available >= rblock.count) {
                lblock.addSlice(rblock.removeSlice());
                break;
            }
        }
    }
    var p2_sum: u64 = 0;
    var idx: u64 = 0;
    for (slice) |e| {
        for (0..e.count) |i| {
            p2_sum += e.elems[i] * idx;
            idx += 1;
        }
        idx += e.available;
    }
    return p2_sum;
}

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
    var buffer: [1_000_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input = "2333133121414131402";
    // End setup

    var fs = std.ArrayList(?Tag).initCapacity(allocator, 100_000) catch unreachable;
    defer fs.deinit();
    var fs2 = std.ArrayList(Block).initCapacity(allocator, input.len) catch unreachable;
    defer fs2.deinit();

    var id: u16 = 0;
    for (input, 0..) |e, i| {
        if (e == '\n') break;
        const len = e - '0';
        var val: ?Tag = null;
        if (@mod(i, 2) == 0) {
            fs2.appendAssumeCapacity(Block.initFile(len, id));
            val = Tag{ .id = @intCast(id) };
            id += 1;
        } else {
            fs2.appendAssumeCapacity(Block.initNull(len));
        }
        for (0..len) |_| fs.appendAssumeCapacity(val);
    }

    const p1_sum = part1(fs.items);
    const p2_sum = part2(fs2.items);
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}
