const std = @import("std");
const StringHashMap = std.StringHashMap;
const str = []const u8;

const T = u32;
const MMap = StringHashMap(T);

pub fn make_example(allocator: std.mem.Allocator) !StringHashMap(MMap) {
    var parentMap = StringHashMap(MMap).init(allocator);
    var childMap = MMap.init(allocator);
    try childMap.put("hello", 324);
    try parentMap.put("foo", childMap);
    return parentMap;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();
    const parentMap = try make_example(allocator);
    const childMap: ?MMap = parentMap.get("foo");
    const value = childMap.?.get("hello");
    std.debug.print("\nValue: {d}\n", .{value.?});
}
