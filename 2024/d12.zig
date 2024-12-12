const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const print = myf.printAny;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;

const CT = i16;
const KT = [2]CT;
const VisitedT = std.AutoArrayHashMap(KT, void);

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
    const input = @embedFile("in/d12.txt");
    // End setup
    const input_attributes = try myf.getInputAttributes(input);

    // Assuming square matrix
    const dimension: u8 = @intCast(input_attributes.row_len);
    var matrix = try allocator.alloc([]u8, dimension);
    defer {
        for (matrix) |row| allocator.free(row);
        allocator.free(matrix);
    }

    var start_pos = std.ArrayList(KT).init(allocator);
    defer start_pos.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    for (0..matrix.len) |i| {
        if (in_iter.next()) |data| {
            matrix[i] = try allocator.alloc(u8, dimension);
            @memcpy(matrix[i], data[0..dimension]);
        }
    }

    var visited = VisitedT.init(allocator);
    defer visited.deinit();

    var regions = std.ArrayList([]KT).init(allocator);
    defer {
        for (regions.items) |region| allocator.free(region);
        regions.deinit();
    }

    const max_dim: CT = @intCast(dimension);

    for (0..dimension) |i| {
        for (0..dimension) |j| {
            const coord: KT = .{ @intCast(i), @intCast(j) };
            if (visited.get(coord) != null) continue;
            const region_key = matrix[i][j];
            try regions.append(dfs(allocator, matrix, max_dim, region_key, &visited, coord));
        }
    }

    var p1_sum: u64 = 0;
    for (regions.items) |region| {
        const area = region.len;
        const perimeter = calcPerimeter(matrix, max_dim, region);
        p1_sum += area * perimeter;
        //
    }
    print(p1_sum);
}

// fn castAway(matrix: []const []const u8, max_dim: CT, region: []ComplexT) void {
//     for (0..matrix.len) |i| {
//         for (0..matrix.len) |j| {
//             //
//         }
//     }
// }
fn calcPerimeter(matrix: []const []const u8, max_dim: CT, region: []KT) u64 {
    const m, const n = region[0];
    const symbol = matrix[@intCast(m)][@intCast(n)];

    var perimeter: u64 = 0;
    for (region) |coord| {
        const row, const col = coord;
        for (myf.getNextPositions(CT, row, col)) |next_position| {
            if (myf.checkInBounds(CT, next_position, max_dim, max_dim)) |valid_pos| {
                if (matrix[valid_pos.row][valid_pos.col] != symbol) {
                    perimeter += 1;
                }
            } else {
                perimeter += 1;
                continue;
            }
        }
    }
    return perimeter;
}

fn dfs(
    alloc: Allocator,
    matrix: []const []const u8,
    max_dim: CT,
    region_key: u8,
    visited: *VisitedT,
    start_coord: KT,
) []KT {
    var stack = std.ArrayList(KT).init(alloc);
    defer stack.deinit();

    // Returns
    var region_coords = std.ArrayList(KT).init(alloc);
    defer region_coords.deinit();

    stack.append(start_coord) catch unreachable;
    while (stack.items.len != 0) {
        const position = stack.pop();

        if (visited.get(position) != null) continue;
        visited.put(position, {}) catch unreachable;
        region_coords.append(position) catch unreachable;

        const row, const col = position;
        for (myf.getNextPositions(CT, row, col)) |next_position| {
            if (myf.checkInBounds(CT, next_position, max_dim, max_dim)) |valid_pos| {
                if (matrix[valid_pos.row][valid_pos.col] == region_key)
                    stack.append(next_position) catch unreachable;
            }
        }
    }
    return region_coords.toOwnedSlice() catch unreachable;
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
