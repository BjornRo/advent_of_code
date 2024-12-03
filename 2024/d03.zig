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
    const T = u64;
    const TR = struct {
        const Self = @This();
        const Result = enum { OK, FAIL, ACCEPT };
        const FnType = *const fn ([]const u8, T) RetType;
        const RetType = struct {
            result: Result,
            next: *const fn ([]const u8, T) RetType,
        };
        const fail = RetType{ .result = .FAIL, .next = Self.m };
        fn retFactory(res: Self.Result, next: Self.FnType) RetType {
            return .{ .result = res, .next = next };
        }

        fn m(in: []const u8, index: T) RetType {
            if (in[index] == 'm') return retFactory(.OK, Self.u);
            return Self.fail;
        }
        fn u(in: []const u8, index: T) RetType {
            if (in[index] == 'u') return retFactory(.OK, Self.l);
            return Self.fail;
        }
        fn l(in: []const u8, index: T) RetType {
            if (in[index] == 'l') return retFactory(.OK, Self.lpar);
            return Self.fail;
        }
        fn lpar(in: []const u8, index: T) RetType {
            if (in[index] == '(') return retFactory(.OK, Self.ldigit);
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
            if (in[index] == ')') return retFactory(.ACCEPT, Self.m); // Accepting
            return Self.fail;
        }
    };

    // const test_str = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    var p1_sum: T = 0;
    p1_sum += 1;
    p1_sum -= 1;

    var f: TR.FnType = TR.m;
    var i: T = 0;
    var found_substr = false;
    var found_start: T = 0;
    while (i < input.len) : (i += 1) {
        const res = f(input, i);
        switch (res.result) {
            .OK => {
                if (!found_substr) {
                    found_substr = true;
                    found_start = i;
                }
                f = res.next;
            },
            .FAIL => {
                found_substr = false;
                f = TR.m;
            },
            .ACCEPT => {
                found_substr = false;
                found_start += 4;
                const comma_idx = std.mem.indexOf(u8, input[found_start..i], ",").?;
                const left = try std.fmt.parseInt(u32, input[found_start .. found_start + comma_idx], 10);
                const right = try std.fmt.parseInt(u32, input[found_start + comma_idx + 1 .. i], 10);
                p1_sum += left * right;
                f = TR.m;
            },
        }
    }
    myf.printAny(p1_sum);
}
