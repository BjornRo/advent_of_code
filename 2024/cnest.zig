const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const StringHashMap = std.StringHashMap;
const str = []const u8;
const print = myf.printAny;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    print(myf.getNextPositions(i8, 2, 1));
}
