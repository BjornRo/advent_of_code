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
        const fail = RetType{ .result = .FAIL, .next = Self.m_or_d };
        const Result = enum { OK, FAIL, ACCEPT };
        const RetType = struct {
            result: Result,
            next: *const fn (u8) RetType,
        };
        const FnType = *const fn (u8) RetType;

        fn retFactory(res: Result, next: FnType) RetType {
            return .{ .result = res, .next = next };
        }
        fn m_or_d(char: u8) RetType {
            if (char == 'm') return retFactory(.OK, Self.u);
            if (char == 'd') return retFactory(.OK, Self.o);
            return Self.fail;
        }
        fn u(char: u8) RetType {
            if (char == 'u') return retFactory(.OK, Self.l);
            return Self.fail;
        }
        fn l(char: u8) RetType {
            if (char == 'l') return retFactory(.OK, Self.lpar);
            return Self.fail;
        }
        fn lpar(char: u8) RetType {
            if (char == '(') return retFactory(.OK, Self.ldigit);
            return Self.fail;
        }
        fn ldigit(char: u8) RetType {
            if (std.ascii.isDigit(char)) return retFactory(.OK, Self.ldigit);
            if (char == ',') return retFactory(.OK, Self.comma);
            return Self.fail;
        }
        fn comma(char: u8) RetType {
            if (std.ascii.isDigit(char)) return retFactory(.OK, Self.rdigit);
            return Self.fail;
        }
        fn rdigit(char: u8) RetType {
            if (std.ascii.isDigit(char)) return retFactory(.OK, Self.rdigit);
            if (char == ')') return retFactory(.ACCEPT, Self.m_or_d);
            return Self.fail;
        }
        // DO, DONT
        fn o(char: u8) RetType {
            if (char == 'o') return retFactory(.OK, Self.n_or_lpar);
            return Self.fail;
        }
        fn n_or_lpar(char: u8) RetType {
            if (char == '(') return retFactory(.OK, Self.drpar);
            if (char == 'n') return retFactory(.OK, Self.squote);
            return Self.fail;
        }
        fn drpar(char: u8) RetType {
            if (char == ')') return retFactory(.ACCEPT, Self.m_or_d);
            return Self.fail;
        }
        fn squote(char: u8) RetType {
            if (char == '\'') return retFactory(.OK, Self.t);
            return Self.fail;
        }
        fn t(char: u8) RetType {
            if (char == 't') return retFactory(.OK, Self.dlpar);
            return Self.fail;
        }
        fn dlpar(char: u8) RetType {
            if (char == '(') return retFactory(.OK, Self.drpar);
            return Self.fail;
        }
    };

    var p1_sum: T = 0;
    var p2_sum: T = 0;

    var f: TR.FnType = TR.m_or_d;
    var i: T = 0;
    var active = true;
    var found_substr = false;
    var found_start: T = 0;
    while (i < input.len) : (i += 1) {
        const char = input[i];
        const res = f(char);
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
                f = TR.m_or_d;
            },
            .ACCEPT => {
                f = TR.m_or_d;
                found_substr = false;
                const slice = input[found_start..i];
                if (slice[0] == 'd') {
                    active = slice[2] == '(';
                    continue;
                }
                const comma_idx = std.mem.indexOf(u8, slice, ",").?;
                const left = try std.fmt.parseInt(u32, slice[4..comma_idx], 10);
                const right = try std.fmt.parseInt(u32, slice[comma_idx + 1 ..], 10);
                const result = left * right;
                p1_sum += result;
                if (active) {
                    p2_sum += result;
                }
            },
        }
    }
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}
