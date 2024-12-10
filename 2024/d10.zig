const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const CT = i8;
const ComplexT = std.math.Complex(CT);
const F = struct {
    inline fn inBounds(pos: ComplexT, max_row: CT, max_col: CT) bool {
        return 0 <= pos.re and pos.re < max_row and 0 <= pos.im and pos.im < max_col;
    }
    inline fn complex_to_u16(c: ComplexT) u16 {
        return @bitCast([2]CT{ c.re, c.im });
    }
    inline fn u16_to_complex(n: u16) ComplexT {
        const res: [2]CT = @bitCast(n);
        return ComplexT{ .re = res[0], .im = res[1] };
    }
    inline fn castComplexT(c: ComplexT) [2]u8 {
        return .{ @bitCast(c.re), @bitCast(c.im) };
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
    const input = @embedFile("in/d10.txt");
    // End setup

    const input_attributes = try myf.getInputAttributes(input);

    // Assuming square matrix
    const dimension: u8 = @intCast(input_attributes.row_len);
    const matrix = try allocator.alloc([]const u8, dimension);
    defer allocator.free(matrix);

    var start_pos = std.ArrayList(ComplexT).init(allocator);
    defer start_pos.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    for (matrix, 0..) |*row, i| {
        if (in_iter.next()) |data| row.* = data;
        for (row.*, 0..) |e, j| {
            if (e == '0') try start_pos.append(ComplexT.init(@intCast(i), @intCast(j)));
        }
    }

    const VisitedT = std.AutoArrayHashMap(u16, void);
    const rot_right = ComplexT.init(0, -1);

    var states = std.ArrayList(struct { pos: ComplexT, visited: VisitedT, count: u64 }).init(allocator);
    defer {
        for (states.items) |*i| i.visited.deinit();
        states.deinit();
    }

    const max_dim: i8 = @intCast(dimension);
    var trailheads = std.AutoArrayHashMap(u16, u64).init(allocator);
    defer trailheads.deinit();

    var direction = ComplexT.init(0, 1);
    var p1_sum: u16 = 0;
    var p2_sum: u16 = 0;
    for (start_pos.items) |s| {
        defer {
            p1_sum += @intCast(trailheads.count());
            trailheads.clearRetainingCapacity();
        }
        try states.append(.{ .pos = s, .visited = VisitedT.init(allocator), .count = 0 });
        while (states.items.len != 0) {
            var state = states.pop();
            defer state.visited.deinit();

            const row, const col = F.castComplexT(state.pos);
            if (matrix[row][col] == '9') {
                try trailheads.put(F.complex_to_u16(state.pos), state.count);
                p2_sum += 1;
                continue;
            }
            if ((try state.visited.getOrPutValue(F.complex_to_u16(state.pos), {})).found_existing)
                continue;

            for (0..4) |_| {
                direction = direction.mul(rot_right);
                const next = state.pos.add(direction);
                if (!F.inBounds(next, max_dim, max_dim)) continue;
                const next_row, const next_col = F.castComplexT(next);
                if ((@as(i8, @intCast(matrix[next_row][next_col])) - @as(i8, @intCast(matrix[row][col]))) == 1)
                    try states.append(.{
                        .pos = next,
                        .visited = try state.visited.clone(),
                        .count = state.count + 1,
                    });
            }
        }
    }
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}

pub fn printPath(allocator: Allocator, matrix: [][]const u8, path: []const u16) !void {
    const stdout = std.io.getStdOut().writer();
    var result = try allocator.alloc([]u8, matrix.len);
    for (matrix, 0..) |row, i| {
        result[i] = @constCast(try allocator.alloc(u8, row.len));
        @memcpy(result[i], row);
    }
    defer {
        for (result) |r| allocator.free(r);
        allocator.free(result);
    }

    for (path) |i| {
        const comp = F.u16_to_complex(i);
        const r: u8 = @intCast(comp.re);
        const c: u8 = @intCast(comp.im);
        result[r][c] = '.';
    }

    for (result) |arr| {
        stdout.print("{s}\n", .{arr}) catch {};
    }
    stdout.print("\n", .{}) catch {};
}
