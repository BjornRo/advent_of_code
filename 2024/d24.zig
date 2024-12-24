const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const PriorityQueue = std.PriorityQueue;
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const time = std.time;
const Allocator = std.mem.Allocator;
const endian = @import("builtin").cpu.arch.endian();

const Set = std.AutoArrayHashMap(u24, void);
const Grid = std.AutoArrayHashMap(u24, Gate);
const InSignals = std.AutoArrayHashMap(u24, bool);
const ChildToParent = std.AutoArrayHashMap(u24, myf.FixedBuffer(u24, 2));

const Op = enum {
    XOR,
    AND,
    OR,

    fn fromChar(char: u8) @This() {
        return switch (char) {
            'X' => .XOR,
            'O' => .OR,
            'A' => .AND,
            else => unreachable,
        };
    }
};

const Gate = struct {
    left: u24,
    right: u24,
    out: u24,
    op: Op,

    const Self = @This();
    fn outValue(self: Self, signals: InSignals, grid: Grid, depth: u8) ?bool {
        if (depth == 255) return null;
        const left_val: ?bool =
            if (signals.get(self.left)) |val| val else grid.get(self.left).?.outValue(signals, grid, depth + 1);
        const right_val: ?bool =
            if (signals.get(self.right)) |val| val else grid.get(self.right).?.outValue(signals, grid, depth + 1);
        if (left_val == null or right_val == null) return null;

        return switch (self.op) {
            .XOR => left_val.? != right_val.?,
            .AND => left_val.? and right_val.?,
            .OR => left_val.? or right_val.?,
        };
    }
};

fn arrToInt(arr: []const u8) u24 {
    const value: u24 = @bitCast([_]u8{ arr[0], arr[1], arr[2] });
    return if (.big == endian) value else @byteSwap(value);
}

fn intToArr(int: u24) [3]u8 {
    const value = if (.big == endian) int else @byteSwap(int);
    return @bitCast(value);
}

fn isStartSignal(value: u24) bool {
    return (value & 0xFFFF) == 0x3030;
}

fn isSignal(value: u24) bool {
    const pfx = value >> 16;
    return pfx == 'y' or pfx == 'x';
}

fn isZ(value: u24) bool {
    return (value >> 16) == 'z';
}

fn findOtherNodeInCluster(set: Set, grid: Grid, reverseGrid: ChildToParent, ignore: u24, final_node: u24) ?u24 {
    for (set.keys()) |id| {
        if (id == ignore) continue;
        if (validGate(grid, reverseGrid, id, final_node)) continue;
        return id;
    }
    return null;
}

fn validGate(grid: Grid, reverseGrid: ChildToParent, id: u24, final_node: u24) bool {
    const gate = grid.get(id).?;
    switch (gate.op) {
        .XOR => {
            if (isZ(gate.out)) return true;
            if (isSignal(gate.left) and reverseGrid.get(gate.out).?.len == 2) {
                return true;
            }
        },
        .AND => {
            if (!isZ(gate.out)) {
                if (reverseGrid.get(gate.out).?.len == 1) return true;
                if (isStartSignal(gate.left) and reverseGrid.get(gate.out).?.len == 2) return true;
            }
        },
        .OR => {
            if (!isZ(gate.out) and reverseGrid.get(gate.out).?.len == 2) return true;
            if (gate.out == final_node) return true;
        },
    }
    return false;
}

fn visitOrCluster(allocator: Allocator, grid: Grid, reverseGrid: ChildToParent, visited: *Set, start: u24) !void {
    var stack = std.ArrayList(u24).init(allocator);
    defer stack.deinit();

    try stack.append(start);

    while (stack.items.len != 0) {
        const current = stack.pop();

        if (visited.contains(current)) continue;
        if (grid.get(current)) |res| {
            if (res.op == .OR) {
                try visited.*.put(res.out, {});
                continue;
            }
            try stack.append(res.left);
            try stack.append(res.right);
        }
        if (reverseGrid.get(current)) |res| {
            var x = res;
            for (x.getSlice()) |node| try stack.append(node);
        }
        if (isSignal(current)) continue;
        try visited.*.put(current, {});
    }
}

fn part1(grid: Grid, signals: InSignals, zee: []const u24) !u64 {
    var number: u64 = 0;
    for (zee) |z| {
        const val: u64 = if (grid.get(z).?.outValue(signals, grid, 0).?) 1 else 0;
        number = number * 2 + val;
    }
    return number;
}

fn part2(allocator: Allocator, grid: *Grid, reverseGrid: ChildToParent, final_node: u24) ![]u8 {
    var set = Set.init(allocator);
    defer set.deinit();

    var buf = myf.FixedBuffer(u24, 8).init();

    for (grid.values()) |gate| {
        if (validGate(grid.*, reverseGrid, gate.out, final_node)) continue;

        defer set.clearRetainingCapacity();
        try visitOrCluster(allocator, grid.*, reverseGrid, &set, gate.out);
        const other_node = findOtherNodeInCluster(set, grid.*, reverseGrid, gate.out, final_node).?;
        var n0 = gate;
        var n1 = grid.*.get(other_node).?;
        n0.out = n1.out;
        n1.out = gate.out;
        grid.*.putAssumeCapacity(n0.out, n0);
        grid.*.putAssumeCapacity(n1.out, n1);
        try buf.append(n0.out);
        try buf.append(n1.out);
    }
    std.mem.sort(u24, &buf.buf, {}, std.sort.asc(u24));

    var result = try allocator.alloc(u8, 3 * 8 + 7);
    var index: u8 = 0;
    for (buf.getSlice(), 0..) |item, i| {
        for (intToArr(item)) |c| {
            result[index] = c;
            index += 1;
        }
        if (i == 7) break;
        result[index] = ',';
        index += 1;
    }
    return result;
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

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);

    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var in_iter = std.mem.tokenizeSequence(u8, input, double_delim);
    const raw_signals = in_iter.next().?;
    const raw_grid = in_iter.next().?;

    var signals = InSignals.init(allocator);
    var grid = Grid.init(allocator);
    var reverseGrid = ChildToParent.init(allocator);
    var zee = std.ArrayList(u24).init(allocator);
    defer {
        grid.deinit();
        reverseGrid.deinit();
        signals.deinit();
        zee.deinit();
    }

    var signal_it = std.mem.tokenizeSequence(u8, raw_signals, input_attributes.delim);
    while (signal_it.next()) |row| try signals.put(arrToInt(row[0..3]), row[row.len - 1] == '1');

    var grid_it = std.mem.tokenizeSequence(u8, raw_grid, input_attributes.delim);
    while (grid_it.next()) |row| {
        var row_iter = std.mem.tokenizeScalar(u8, row, ' ');
        const left = arrToInt(row_iter.next().?);
        const op = Op.fromChar(row_iter.next().?[0]);
        const right = arrToInt(row_iter.next().?);
        _ = row_iter.next(); // Arrow
        const out_str = row_iter.next().?;
        const out = arrToInt(out_str);

        if (isZ(out)) try zee.append(out);
        try grid.put(out, .{ .left = left, .right = right, .out = out, .op = op });

        inline for (.{ left, right }) |item| {
            const result = try reverseGrid.getOrPut(item);
            if (!result.found_existing) result.value_ptr.*.len = 0;
            try result.value_ptr.*.append(out);
        }
    }
    std.mem.sort(u24, zee.items, {}, std.sort.desc(u24));

    const result = try part2(allocator, &grid, reverseGrid, zee.items[0]);
    defer allocator.free(result);

    try writer.print("Part 1: {d}\nPart 2: {s}\n", .{ try part1(grid, signals, zee.items), result });
}

test "casting" {
    const str0 = "abx";
    const int0 = arrToInt(str0);
    try expect(std.mem.eql(u8, str0, &intToArr(int0)));
    const str1 = "z01";
    const int1 = arrToInt(str1);
    try expect(std.mem.eql(u8, str1, &intToArr(int1)));
    const str2 = "z00";
    const int2 = arrToInt(str2);
    try expect(std.mem.eql(u8, str2, &intToArr(int2)));
    const str3 = "00z";
    const int3 = arrToInt(str3);
    try expect(std.mem.eql(u8, str3, &intToArr(int3)));
    try expect(int0 != int1 and int0 != int2 and int0 != int3 and int1 != int2 and int1 != int3);
}
