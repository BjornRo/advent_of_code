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

    var max_count = std.ArrayList(u64).init(allocator);
    defer max_count.deinit();
    const max_dim: i8 = @intCast(dimension);
    var direction = ComplexT.init(0, 1);

    var trailheads = std.AutoArrayHashMap(u16, u64).init(allocator);
    defer trailheads.deinit();
    var p1_sum: u32 = 0;
    p1_sum += 0;
    var p2_sum: u32 = 0;
    p2_sum += 0;
    for (start_pos.items) |s| {
        // for (0..1) |_| {
        defer trailheads.clearRetainingCapacity();
        // const s = start_pos.items[0];
        try states.append(.{ .pos = s, .visited = VisitedT.init(allocator), .count = 0 });
        defer {
            // print(trailheads.count());
            p1_sum += @intCast(trailheads.count());
            p2_sum += @intCast(max_count.items.len);
            // print(max_count.items.len);
            // const slice = max_count.items;
            // std.mem.sort(u64, slice, {}, std.sort.desc(u64));
            // var local_s: u64 = 0;
            // for (slice) |e| {
            //     if (e != slice[0]) break;
            //     p1_sum += 1;
            //     local_s += 1;
            // }
            // print(max_count.items);
            // for (visited.keys()) |k| {
            //     const c = F.u16_to_complex(k);
            //     std.debug.print("[{d},{d}] ", .{ c.re, c.im });
            // }
            // std.debug.print("\n", .{});
            max_count.clearRetainingCapacity();
        }
        while (states.items.len != 0) {
            const state = states.pop();
            var visited = state.visited;
            defer visited.deinit();

            const row, const col = F.castComplexT(state.pos);
            if (matrix[row][col] == '9') {
                try trailheads.put(F.complex_to_u16(state.pos), state.count);
                // if (res.found_existing) {
                //     const prev_value = res.value_ptr.*;
                //     if (prev_value >= )
                // }
                try max_count.append(state.count);
                if (state.count == 15) {
                    // for (visited.keys()) |k| {
                    //     const c = F.u16_to_complex(k);
                    //     std.debug.print("[{d},{d}] ", .{ c.re, c.im });
                    // }
                    // std.debug.print("\n", .{});
                    try printPath(allocator, matrix, visited.keys());
                }
                continue;
            }
            const res = try visited.getOrPutValue(F.complex_to_u16(state.pos), {});
            if (res.found_existing) {
                continue;
            }

            const current_value = matrix[row][col];
            for (0..4) |_| {
                direction = direction.mul(rot_right);
                const next = state.pos.add(direction);
                if (!F.inBounds(next, max_dim, max_dim)) continue;
                const next_row, const next_col = F.castComplexT(next);
                const next_value = matrix[next_row][next_col];
                if ((@as(i8, @intCast(next_value)) - @as(i8, @intCast(current_value))) == 1)
                    try states.append(.{ .pos = next, .visited = try visited.clone(), .count = state.count + 1 });
            }
        }
    }
    print(p1_sum);
    print(p2_sum);
    // myf.printMat(u8, matrix, '0');
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
