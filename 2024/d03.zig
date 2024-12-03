const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const expect = std.testing.expect;
const time = std.time;

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000_000);
        writer.print("\nTime taken: {d:.10}s\n", .{elapsed}) catch {};
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    const test_str = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";

    const T = u32;
    const TR = struct {
        const Self = @This();
        const RetType = struct {
            result: enum { OK, FAIL, ACCEPT },
            next: fn ([]const u8, usize) RetType,
        };
        const fail = RetType{ .result = .FAIL, .next = Self.m };
        fn retFactory(res: RetType.result, next: RetType.next) RetType {
            return .{ .result = res, .next = next };
        }

        fn m(in: []const u8, index: T) RetType {
            if (in[index] == 'm') return retFactory(.OK, Self.u);
            return Self.fail;
        }
        fn u(in: []const u8, index: T) RetType {
            if (in[index] == 'm') return retFactory(.OK, Self.l);
            return Self.fail;
        }
        fn l(in: []const u8, index: T) RetType {
            if (in[index] == 'm') return retFactory(.OK, Self.lpar);
            return Self.fail;
        }
        fn lpar(in: []const u8, index: T) RetType {
            if (in[index] == 'm') return retFactory(.OK, Self.ldigit);
            return Self.fail;
        }
        fn ldigit(in: []const u8, index: T) RetType {
            if (std.ascii.isDigit(in[index])) return retFactory(.OK, Self.ldigit);
            if (in[index] == ',') return retFactory(.OK, Self.comma);
            return Self.fail;
        }
        fn comma(in: []const u8, index: T) RetType {
            if (std.ascii.isDigit(in[index])) return retFactory(.OK, Self.rdigit);
            return Self.fail;
        }
        fn rdigit(in: []const u8, index: T) RetType {
            if (std.ascii.isDigit(in[index])) return retFactory(.OK, Self.rdigit);
            if (in[index] == ')') return retFactory(.OK, Self.rpar);
            return Self.fail;
        }
        fn rpar(_: []const u8, _: T) RetType { // accept
            return retFactory(.ACCEPT, Self.m);
        }
    };
}
