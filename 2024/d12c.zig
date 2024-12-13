const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const CT = i16;
const ComplexT = std.math.Complex(CT);
const KT = [2]CT;
const VisitedT = std.AutoArrayHashMap(KT, void);

const pad = '.';

inline fn inBounds(pos: ComplexT, max_row: CT, max_col: CT) bool {
    return 0 <= pos.re and pos.re < max_row and 0 <= pos.im and pos.im < max_col;
}
inline fn castComplexT(c: ComplexT) KT {
    return .{ @bitCast(c.re), @bitCast(c.im) };
}
pub fn eql(a: ComplexT, b: ComplexT) bool {
    return a.re == b.re and a.im == b.im;
}
inline fn complexTo64(c: ComplexT, d: ComplexT) u64 {
    return @bitCast([4]i16{ c.re, c.im, d.re, d.im });
}
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
    const dimension: u16 = @intCast(input_attributes.row_len);
    var matrix = try allocator.alloc([]const u8, dimension);
    defer allocator.free(matrix);

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    for (0..matrix.len) |i| {
        if (in_iter.next()) |data| matrix[i] = data;
    }

    var visited = VisitedT.init(allocator);
    defer visited.deinit();

    var regions = std.ArrayList(std.AutoArrayHashMap(KT, void)).init(allocator);
    defer {
        for (regions.items) |*region| region.deinit();
        regions.deinit();
    }

    const pad_matrix = try myf.padMatScalar(u8, allocator, matrix, pad);
    defer {
        for (pad_matrix) |r| allocator.free(r);
        allocator.free(pad_matrix);
    }

    for (1..dimension + 1) |i| {
        for (1..dimension + 1) |j| {
            const coord: KT = .{ @intCast(i), @intCast(j) };
            if (visited.get(coord) != null) continue;
            const region_key = pad_matrix[i][j];
            try regions.append(dfs(allocator, pad_matrix, region_key, &visited, coord));
        }
    }

    var p1_sum: u64 = 0;
    for (regions.items) |region| {
        const area = region.keys().len;
        const perimeter = calcPerimeter(pad_matrix, region.keys());
        p1_sum += area * perimeter;
        //
    }
    print(p1_sum);

    var p2_sum: u64 = 0;
    for (regions.items, 0..) |region, i| {
        var border = paintBorders(allocator, pad_matrix, region);
        defer border.deinit();
        printRegion(allocator, pad_matrix, border.keys());
        const corners = cornerFinder(allocator, border, region);
        if (corners == 21) break;
        p2_sum += corners * regions.items[i].keys().len;
    }
    print(p2_sum);
}

fn paintBorders(alloc: Allocator, matrix: []const []const u8, region: VisitedT) VisitedT {
    var region_coords = VisitedT.init(alloc);
    for (region.keys()) |coord| {
        const row, const col = coord;
        for (myf.getKernel3x3(CT, row, col)) |next_position| {
            const next_row, const next_col = next_position;
            const mat_elem = matrix[@intCast(next_row)][@intCast(next_col)];
            if (region.get(.{ next_row, next_col }) == null or mat_elem == pad) {
                region_coords.put(.{ next_row, next_col }, {}) catch unreachable;
            }
        }
    }
    return region_coords;
}
fn cornerFinder(_: Allocator, border: VisitedT, _: VisitedT) u64 {
    var borders: u64 = 0;
    defer print(borders);
    for (border.keys()) |position| {
        const row, const col = position;
        const left = border.get(.{ row, col - 1 });
        const right = border.get(.{ row, col + 1 });
        const up = border.get(.{ row - 1, col });
        const down = border.get(.{ row + 1, col });
        const old_borders = borders;
        defer {
            if (old_borders != borders) {
                // std.debug.print("{d}\n", .{position});
                // std.debug.print("{d},{d}\n", .{ old_borders, borders });
            }
        }
        // 01, left null, up+right || // 14 down null, right+up
        if ((left == null and up != null and right != null) or
            (down == null and right != null and up != null)) borders += 1;
        // std.debug.print("{d},{d}\n", .{ 1, borders });
        if (old_borders != borders) continue;
        // 02 up null, right+down || // 13 left null, down+right
        if ((up == null and right != null and down != null) or
            (left == null and down != null and right != null)) borders += 1;
        // std.debug.print("{d},{d}\n", .{ 2, borders });
        if (old_borders != borders) continue;
        // 03 right null, down+left || // 12 up null, left+down
        if ((right == null and down != null and left != null) or
            (up == null and left != null and down != null)) borders += 1;
        // std.debug.print("{d},{d}\n", .{ 3, borders });
        if (old_borders != borders) continue;
        // 04 down null, left+up || // 11 right null, up+left
        if ((down == null and left != null and up != null) or
            (right == null and up != null and left != null)) borders += 1;
        // std.debug.print("{d},{d}\n", .{ 4, borders });
        if (old_borders != borders) continue;
        if (left == null and up == null and right == null and down == null) {
            borders += 4;
            continue;
        }

        // Dead ends
        if (left == null and up == null and right == null) borders += 2;
        if (up == null and right == null and down == null) borders += 2;
        if (right == null and down == null and left == null) borders += 2;
        if (down == null and left == null and up == null) borders += 2;
    }
    return borders;
}

fn calcPerimeter(matrix: []const []const u8, region: []KT) u64 {
    const m, const n = region[0];
    const symbol = matrix[@intCast(m)][@intCast(n)];

    var perimeter: u64 = 0;
    for (region) |coord| {
        const row, const col = coord;
        for (myf.getNextPositions(CT, row, col)) |next_position| {
            const next_row, const next_col = next_position;
            const mat_elem = matrix[@intCast(next_row)][@intCast(next_col)];
            if (mat_elem != symbol or mat_elem == pad) {
                perimeter += 1;
            }
        }
    }
    return perimeter;
}

fn dfs(
    alloc: Allocator,
    matrix: []const []const u8,
    region_key: u8,
    visited: *VisitedT,
    start_coord: KT,
) std.AutoArrayHashMap(KT, void) {
    var stack = std.ArrayList(KT).init(alloc);
    defer stack.deinit();

    // Returns
    var region_coords = std.AutoArrayHashMap(KT, void).init(alloc);

    stack.append(start_coord) catch unreachable;
    while (stack.items.len != 0) {
        const position = stack.pop();

        if (visited.get(position) != null) continue;
        visited.put(position, {}) catch unreachable;
        region_coords.put(position, {}) catch unreachable;

        const row, const col = position;
        for (myf.getNextPositions(CT, row, col)) |next_position| {
            const next_row, const next_col = next_position;
            const mat_elem = matrix[@intCast(next_row)][@intCast(next_col)];
            if (mat_elem == pad) continue;
            if (mat_elem != region_key) continue;
            stack.append(next_position) catch unreachable;
        }
    }
    return region_coords;
}

pub fn printRegion(allocator: Allocator, matrix: [][]const u8, region: []const KT) void {
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
        const r: u8 = @intCast(comp[0]);
        const c: u8 = @intCast(comp[1]);
        result[r][c] = '#';
    }

    for (result) |arr| {
        stdout.print("{s}\n", .{arr}) catch unreachable;
    }
    stdout.print("\n", .{}) catch unreachable;
}
