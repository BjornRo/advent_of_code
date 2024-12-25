const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const StringHashMap = std.StringHashMap;
const str = []const u8;
const print = myf.printAny;

fn f(char: u8) []const u8 {
    if (char == '0') {
        return "abba";
    }
    return "bbabdd";
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    print(try myf.crt(i32, &[_]i32{ 52, 27 }, &[_]i32{ 101, 103 }));

    const a: u64 = 1;
    // const b: u32 = 33;
    print(myf.concatInts(u64, a, 0));
    // print(try myf.modInverse(i128, 4, 4));

    var b = try allocator.alloc(u8, 16);
    for (0..16) |i| b[i] = @intCast(i);
    const data = @as(*[4][4]u8, @ptrCast(b)).*; // deref copies?
    std.debug.print("{*}\n", .{&data});
    std.debug.print("{*}\n", .{&b});
    b[0] = 4;
    print(b);
    print(data);
    allocator.free(b);
    std.debug.print("{*}\n", .{&data});
    std.debug.print("{*}\n", .{&b});

    print(f('0'));
    print(f('1'));

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
