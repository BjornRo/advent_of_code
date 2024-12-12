const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const CT = i8;
const ComplexT = std.math.Complex(CT);
const VisitedT = std.ArrayHashMap(ComplexT, void, HashCtx, true);
const F = struct {
    inline fn inBounds(pos: ComplexT, max_row: CT, max_col: CT) bool {
        return 0 <= pos.re and pos.re < max_row and 0 <= pos.im and pos.im < max_col;
    }
    inline fn u16_to_complex(n: u16) ComplexT {
        const res: [2]CT = @bitCast(n);
        return ComplexT{ .re = res[0], .im = res[1] };
    }
    inline fn castComplexT(c: ComplexT) [2]u8 {
        return .{ @bitCast(c.re), @bitCast(c.im) };
    }
};

const HashCtx = struct {
    pub fn hash(_: @This(), key: ComplexT) u16 {
        return @bitCast([2]CT{ key.re, key.im });
    }
    pub fn eql(_: @This(), a: ComplexT, b: ComplexT, _: usize) bool {
        return a.re == b.re and a.im == b.im;
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
    const input = @embedFile("in/d12t.txt");
    // End setup
    const input_attributes = try myf.getInputAttributes(input);

    // Assuming square matrix
    const dimension: u8 = @intCast(input_attributes.row_len);
    const matrix = try allocator.alloc([]const u8, dimension);
    defer allocator.free(matrix);

    var start_pos = std.ArrayList(ComplexT).init(allocator);
    defer start_pos.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    for (matrix) |*row| {
        if (in_iter.next()) |data| row.* = data;
    }

    var visited = VisitedT.init(allocator);
    defer visited.deinit();

    var regions = std.ArrayList([]ComplexT).init(allocator);
    defer {
        for (regions.items) |region| allocator.free(region);
        regions.deinit();
    }

    for (0..dimension) |i| {
        for (0..dimension) |j| {
            const coord = ComplexT.init(@intCast(i), @intCast(j));
            if (visited.get(coord) != null) continue;
            const region_key = matrix[i][j];
            try regions.append(bfs(allocator, matrix, @intCast(dimension), region_key, &visited, coord));
            break;
        }
        break;
    }
    printRegion(allocator, matrix, regions.items[0]);
}

// https://www.geeksforgeeks.org/find-perimeter-shapes-formed-1s-binary-matrix/

fn bfs(
    alloc: Allocator,
    matrix: []const []const u8,
    max_dim: CT,
    region_key: u8,
    visited: *VisitedT,
    start_coord: ComplexT,
) []ComplexT {
    var stack = std.ArrayList(ComplexT).init(alloc);
    defer stack.deinit();

    // Returns
    var region_coords = std.ArrayList(ComplexT).init(alloc);
    defer region_coords.deinit();

    const rot_right = ComplexT.init(0, -1);
    var direction = ComplexT.init(0, 1);
    stack.append(start_coord) catch unreachable;
    while (stack.items.len != 0) {
        var position = stack.pop();

        if (visited.get(position) != null) continue;
        visited.put(position, {}) catch unreachable;
        region_coords.append(position) catch unreachable;

        for (0..4) |_| {
            direction = direction.mul(rot_right);
            const next_position = position.add(direction);
            if (F.inBounds(next_position, max_dim, max_dim)) {
                const row, const col = F.castComplexT(next_position);
                if (matrix[row][col] == region_key) stack.append(next_position) catch unreachable;
            }
        }
    }
    return region_coords.toOwnedSlice() catch unreachable;
}

pub fn printRegion(allocator: Allocator, matrix: [][]const u8, region: []const ComplexT) void {
    const stdout = std.io.getStdOut().writer();
    var result = allocator.alloc([]u8, matrix.len) catch unreachable;
    for (matrix, 0..) |row, i| {
        result[i] = @constCast(allocator.alloc(u8, row.len) catch unreachable);
        @memcpy(result[i], row);
    }
    defer {
        for (result) |r| allocator.free(r);
        allocator.free(result);
    }

    for (region) |comp| {
        const r: u8 = @intCast(comp.re);
        const c: u8 = @intCast(comp.im);
        result[r][c] = '#';
    }

    for (result) |arr| {
        stdout.print("{s}\n", .{arr}) catch unreachable;
    }
    stdout.print("\n", .{}) catch unreachable;
}
