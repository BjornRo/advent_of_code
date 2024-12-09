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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input = @embedFile("in/d09.txt");
    // const input = "2333133121414131402";
    // End setup

    // alternating: Length of file, length of free.

    var fs = std.ArrayList(?Tag).init(allocator);
    defer fs.deinit();

    var id: u16 = 0;
    // var total_size: u64 = 0;
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
        if (e) |v| {
            p1_sum += i * v.id;
        }
    }
    print(p1_sum);

    slice = fs2.items;

    right = slice.len - 1;
    var tmp: [10]?Tag = .{null} ** 10;
    tmp[0] = null;
    var curr_id = Tag{ .id = 0 };
    var right_start: u64 = 0;
    var left_end: u64 = 0;

    while (true) {
        while (slice[right] == null) right -= 1;
        curr_id = slice[right] orelse unreachable;
        right_start = right - 1;

        var exit = false;
        while (slice[right_start] != null and
            curr_id.eq(slice[right_start] orelse unreachable))
        {
            if (right_start == 0) {
                exit = true;
                break;
            }
            right_start -= 1;
        }
        if (exit) break;

        left = 0;
        const right_size = right - right_start;
        while (left < right_start) {
            while (slice[left] != null) {
                left += 1;
                // No empty slots, break to outer loop
                if (left >= right_start) {
                    right -= right_size;
                    break;
                }
            } else {
                // We found null, find the range
                left_end = left + 1;
                while (slice[left_end] == null) {
                    left_end += 1;
                    if (left_end >= right_start) break;
                } else {
                    const left_size: u64 = left_end - left;
                    // No range long enough, continue searching

                    if (left_size < right_size) {
                        // move left to next position
                        left += left_size;
                        continue;
                    } else {
                        // We found a range, move the items
                        const right_slice = slice[right_start + 1 .. right + 1];
                        const left_slice = slice[left .. left + right_size];
                        const tmp_slice = tmp[0..right_size];
                        @memcpy(tmp_slice, right_slice);
                        @memcpy(right_slice, left_slice);
                        @memcpy(left_slice, tmp_slice);
                        left += right_size;
                        right -= right_size;
                    }
                }
            }
            break;
            // No empty slots, we found a spot, or we need to move right slice
        }
    }

    var p2_sum: u64 = 0;
    for (slice, 0..) |e, i| {
        if (e) |v| {
            p2_sum += i * v.id;
        }
    }
    print(p2_sum);
}

fn p(slice: []?Tag) void {
    for (slice) |e| {
        if (e) |v| {
            var buf: [4]u8 = undefined;
            const numAsString = std.fmt.bufPrint(&buf, "{}", .{v.id}) catch unreachable;
            std.debug.print("{s}", .{numAsString});
        } else {
            std.debug.print(".", .{});
        }
    }
    std.debug.print("\n", .{});
}

// fn a() void {
//     const Block = struct {
//         size: u8,
//         count: u8,
//         elems: [9]u16,

//         const Self = @This();
//         fn add(self: *Self, o: u8) void {
//             self.elems[self.count] = o;
//             self.count += 1;
//         }
//     };

//     // var total_size: u64 = 0;
//     for (.{1,2,3}, 0..) |e, i| {
//         if (e == '\n') break;
//         const len = e - '0';
//         var val: ?Tag = null;
//         var block = Block{ .size = len, .count = 0, .elems = .{0} ** 9 };
//         if (@mod(i, 2) == 0) {
//             val = Tag{ .id = @intCast(id) };
//             for (0..len) |_| block.add(@intCast(id));
//             id += 1;
//         }
//         for (0..len) |_| try fs.append(val);
//         try fs2.append(block);
//     }
// }

// {
//     left_size = left_end - left;
//     if (left_size >= right_size) {
//         const right_slice = slice[right_start + 1 .. right + 1];
//         const left_slice = slice[left .. left + right_size];
//         const tmp_slice = tmp[0..right_size];
//         @memcpy(tmp_slice, right_slice);
//         @memcpy(right_slice, left_slice);
//         @memcpy(left_slice, tmp_slice);
//         break;
//     } else {
//         left += 1;
//         right -= right_size;
//         break;
//     }
// }

// var left_size: u64 = 0;
// while (left_end < right_start) {
//     while (slice[left] != null) left += 1;
//     left_end = left + 1;
//     while (slice[left_end] == null) {
//         left_end += 1;
//         if (left_end >= right_start) break;
//     } else {
//         left_size = left_end - left;
//         if (left_size >= right_size) {
//             const right_slice = slice[right_start + 1 .. right + 1];
//             const left_slice = slice[left .. left + right_size];
//             const tmp_slice = tmp[0..right_size];
//             @memcpy(tmp_slice, right_slice);
//             @memcpy(right_slice, left_slice);
//             @memcpy(left_slice, tmp_slice);
//             break;
//         } else {
//             left += 1;
//             right -= right_size;
//             break;
//         }
//     }
// }

// if (left_size >= right_size) {}
// left += right_size;
// right -= right_size;
