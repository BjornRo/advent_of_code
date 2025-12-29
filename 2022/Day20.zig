const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

const CT = i64;
const List = std.ArrayList(struct { usize, CT });
pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d20.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

fn solve(alloc: Allocator, data: []const u8) !struct { p1: CT, p2: CT } {
    var list: List = .empty;
    defer list.deinit(alloc);

    var split_iter = std.mem.splitScalar(u8, data, '\n');
    var i: usize = 0;
    while (split_iter.next()) |item| : (i += 1) {
        var num_iter = utils.NumberIter(CT).init(item);
        while (num_iter.next()) |value| try list.append(alloc, .{ i, value });
    }

    var cloned = try list.clone(alloc);
    defer cloned.deinit(alloc);
    for (list.items) |*e| e.@"1" *= 811589153;
    return .{ .p1 = solver(&cloned, 1), .p2 = solver(&list, 10) };
}
fn solver(list: *List, times: usize) CT {
    const slice = list.items;
    const N: @TypeOf(slice[0].@"1") = @intCast(slice.len - 1);
    for (0..times) |_| for (0..slice.len) |i| for (slice, 0..) |e, j|
        if (e.@"1" != 0 and e.@"0" == i) {
            const elem = list.orderedRemove(j);
            list.insertAssumeCapacity(@intCast(@mod(elem.@"1" + @as(CT, @intCast(j)), N)), elem);
            break;
        };
    var sum: CT = 0;
    for (slice, 0..) |e, j|
        if (e.@"1" == 0) {
            for (1..4) |i| sum += slice[(j + i * 1000) % slice.len].@"1";
            break;
        };
    return sum;
}
