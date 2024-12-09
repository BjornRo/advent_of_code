const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const Tag = struct {
    id: u16,
    const Self = @This();
    fn eq(self: Self, o: Self) bool {
        return self.id == o.id;
    }
};

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
    std.debug.print("Input size: {d}\n\n", .{input.len});
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input = @embedFile("in/d09.txt");
    // End setup

    var fs = std.ArrayList(?Tag).init(allocator);
    defer fs.deinit();

    var id: u16 = 0;
    for (input, 0..) |e, i| {
        if (e == '\n') break;
        const len = e - '0';
        var val: ?Tag = null;
        if (@mod(i, 2) == 0) {
            val = Tag{ .id = @intCast(id) };
            id += 1;
        }
        for (0..len) |_| try fs.append(val);
    }

    var fs2 = try fs.clone();
    defer fs2.deinit();

    var slice = fs.items;
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

    var tmp: [10]?Tag = undefined;

    slice = fs2.items;
    var right_iter = RightIterator.init(slice);
    while (right_iter.next()) |res| {
        const size: u8 = @intCast(res.partition.len);
        const found_left = findLeft(res.rest, size);
        if (found_left == null) continue;
        @memcpy(tmp[0..size], res.partition);
        @memcpy(res.partition, found_left.?[0..size]);
        @memcpy(found_left.?[0..size], tmp[0..size]);
    }
    var p2_sum: u64 = 0;
    for (slice, 0..) |e, i| {
        if (e) |v| p2_sum += i * v.id;
    }
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}

fn findLeft(slice: []?Tag, size: u8) ?[]?Tag {
    if (slice.len == 0) return null;

    var found_start = false;
    var start: u32 = 0;

    for (slice, 0..) |t, i| {
        if (!found_start) {
            if (t == null) {
                found_start = true;
                start = @intCast(i);
            }
        } else {
            if (t != null) {
                const new_slice = slice[start..i];
                if (new_slice.len >= size) return new_slice;
                found_start = false;
            }
        }
    }
    if (found_start) {
        const new_slice = slice[start..slice.len];
        if (new_slice.len >= size) return new_slice;
    }
    return null;
}

const RightIterator = struct {
    slice: []?Tag,
    pointer: u32,

    const Self = @This();
    fn init(slice: []?Tag) Self {
        return .{
            .slice = slice,
            .pointer = @intCast(slice.len - 1),
        };
    }

    fn next(self: *Self) ?struct { rest: @TypeOf(self.slice), partition: @TypeOf(self.slice) } {
        if (self.pointer == 0) return null;
        var end_idx: u32 = 0;
        var tag: Tag = Tag{ .id = 0 };
        while (true) {
            if (self.slice[self.pointer]) |t| {
                end_idx = self.pointer + 1;
                tag = t;
                break;
            }
            if (self.pointer == 0) return null;
            self.pointer -= 1;
        }
        while (true) {
            const curr = self.slice[self.pointer];
            if (curr == null or !curr.?.eq(tag)) {
                self.pointer += 1;
                break;
            }
            if (self.pointer == 0) break;
            self.pointer -= 1;
        }
        defer {
            if (self.pointer != 0) self.pointer -= 1;
        }
        return .{
            .rest = self.slice[0..self.pointer],
            .partition = self.slice[self.pointer..end_idx],
        };
    }
};

// fn p(slice: []?Tag) void {
//     for (slice) |e| {
//         if (e) |v| {
//             var buf: [4]u8 = undefined;
//             const numAsString = std.fmt.bufPrint(&buf, "{}", .{v.id}) catch unreachable;
//             std.debug.print("{s}", .{numAsString});
//         } else {
//             std.debug.print(".", .{});
//         }
//     }
//     std.debug.print("\n", .{});
// }
