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

    print(try myf.crt(i32, &[_]i32{ 52, 27 }, &[_]i32{ 101, 103 }));
    // print(try myf.modInverse(i128, 4, 4));

    // print(@typeInfo(@TypeOf(myf.getNextPositions)).Fn.return_type.?);
    // print(myf.getNextPositions(i8, 3, 3));
    // var neighbors = myf.validNeighborsIter(myf.getKernel3x3(i8, 3, 3), 0, 5, 5);
    // _ = myf.validNeighborsIter(i8, myf.getKernel3x3, 5, 4, 0, 5, 5);
    // print(neighbors.next());
    // print(neighbors.next());
    // print(neighbors.next());
    // print(neighbors.next());
    // print(neighbors.next());
    // print(neighbors.next());
    // print(neighbors.next());
    // const pos = [2]i8{ 1, 2 };
    // print(
    //     myf.rotateRight(
    //         @TypeOf(pos[0]),
    //         myf.rotateRight(
    //             @TypeOf(pos[0]),
    //             myf.rotateRight(
    //                 @TypeOf(pos[0]),
    //                 myf.rotateRight(
    //                     @TypeOf(pos[0]),
    //                     pos,
    //                 ),
    //             ),
    //         ),
    //     ),
    // );
    // print(myf.rotateLeft(@TypeOf(pos[0]), pos));
}
