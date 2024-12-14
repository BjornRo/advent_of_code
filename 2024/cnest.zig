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

    print(myf.getNextPositions(i8, 3, 3));
    var neighbors = myf.validNeighborsIter(i8, 5, 4, 0, 5, 5);
    print(neighbors.next());
    print(neighbors.next());
    print(neighbors.next());
    print(neighbors.next());
    const pos = [2]i8{ 1, 2 };
    print(
        myf.rotateRight(
            @TypeOf(pos[0]),
            myf.rotateRight(
                @TypeOf(pos[0]),
                myf.rotateRight(
                    @TypeOf(pos[0]),
                    myf.rotateRight(
                        @TypeOf(pos[0]),
                        pos,
                    ),
                ),
            ),
        ),
    );
    print(myf.rotateLeft(@TypeOf(pos[0]), pos));
}
