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

const CT = i8;
const VisitedBuf = myf.FixedBuffer(u8, 8);
const PathBuf = myf.FixedBuffer(u8, 16);
const Key = struct { level: u8, path: []const u8 };

const HashCtx = struct {
    pub fn hash(_: @This(), key: Key) u64 {
        const level: u64 = @intCast(key.level);
        const khash = std.hash.Murmur2_64.hash(key.path) + level;
        return khash;
    }
    pub fn eql(_: @This(), a: Key, b: Key) bool {
        return a.level == b.level and std.mem.eql(u8, a.path, b.path);
    }
};

const Set = std.HashMap(Key, u64, HashCtx, 95);

const Point = struct {
    row: CT,
    col: CT,

    const Self = @This();

    fn init(row: anytype, col: anytype) Self {
        return .{ .row = @intCast(row), .col = @intCast(col) };
    }
    fn cast(self: Self) [2]u8 {
        return .{ @intCast(self.row), @intCast(self.col) };
    }
    fn toArr(self: Self) [2]CT {
        return .{ self.row, self.col };
    }
    fn manhattan(self: Self, p: Self) CT {
        const res = myf.manhattan(self.toArr(), p.toArr());
        return @intCast(res);
    }
    fn addA(self: Self, arr: [2]CT) Point {
        return .{
            .row = self.row + arr[0],
            .col = self.col + arr[1],
        };
    }
};

const A = 10;
const keypad_str = [4]*const [3:0]u8{
    "789",
    "456",
    "123",
    " 0A",
};

const rows: i8 = keypad_str.len;
const cols: i8 = keypad_str[0].len;

const keypad_map = blk: {
    const X = 16; // just placeholder. Invalid case
    const keypad_matrix = [_][3]i8{
        .{ 7, 8, 9 },
        .{ 4, 5, 6 },
        .{ 1, 2, 3 },
        .{ X, 0, A },
    };
    const buttons = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A };
    var btn_coord: [buttons.len]Point = undefined;
    outer: for (buttons) |val| {
        for (0..rows) |i| {
            for (0..cols) |j| {
                if (val == keypad_matrix[i][j]) {
                    btn_coord[val] = Point.init(i, j);
                    continue :outer;
                }
            }
        }
    }

    break :blk btn_coord;
};

fn dirpad(key: u8) []const u8 {
    return switch (key) {
        '^' => "vA",
        'A' => "^>",
        '<' => "v",
        'v' => "<^>",
        '>' => "Av",
        else => unreachable,
    };
}

fn direction(start: u8, to: u8) u8 {
    if (start == 'A' and to == '^' or start == 'v' and to == '<' or start == '>' and to == 'v') return '<';
    if (start == '<' and to == 'v' or start == 'v' and to == '>' or start == '^' and to == 'A') return '>';
    if (start == 'v' and to == '^' or start == '>' and to == 'A') return '^';
    if (start == 'A' and to == '>' or start == '^' and to == 'v') return 'v';
    unreachable;
}

fn getManhattanDist(from_char: u8, to_char: u8) u8 {
    const from_point = keypad_map[std.fmt.charToDigit(from_char, 16) catch unreachable];
    const to_point = keypad_map[std.fmt.charToDigit(to_char, 16) catch unreachable];
    return @intCast(from_point.manhattan(to_point));
}

fn keypad(allocator: Allocator, input_row: []const u8, n_robots: u8, memo: *Set) !u64 {
    const State = struct {
        position: Point,
        visited: VisitedBuf,
        path: PathBuf,
        max_steps: u8,
        to_visit: []const u8,
    };

    var shortest_path: u64 = std.math.maxInt(u64);

    var stack = std.ArrayList(State).init(allocator);
    defer stack.deinit();
    try stack.append(.{
        .position = keypad_map[A],
        .visited = VisitedBuf.init(),
        .path = PathBuf.init(),
        .max_steps = getManhattanDist('A', input_row[0]),
        .to_visit = input_row,
    });

    while (stack.items.len != 0) {
        var state = stack.pop();
        const row, const col = state.position.cast();
        var elem = keypad_str[row][col];
        if (elem == state.to_visit[0]) {
            var new_path = state.path;
            try new_path.append('A');
            if (state.to_visit.len == 1) {
                const result = try robots(allocator, n_robots, new_path.getSlice(), memo);
                if (result < shortest_path) shortest_path = result;
                continue;
            }
            try stack.append(.{
                .position = state.position,
                .visited = VisitedBuf.init(),
                .path = new_path,
                .max_steps = getManhattanDist(state.to_visit[0], state.to_visit[1]),
                .to_visit = state.to_visit[1..],
            });
            continue;
        }

        if (state.visited.contains(@intCast(elem)) or state.visited.len >= state.max_steps) {
            continue;
        }
        var new_visited = state.visited;
        try new_visited.append(@intCast(elem));

        for (myf.getNeighborOffset(CT), [4]u8{ 'v', '>', '^', '<' }) |next_pos, dir| {
            const new_pos = state.position.addA(next_pos);
            if (0 <= new_pos.row and new_pos.row < rows and 0 <= new_pos.col and new_pos.col < cols) {
                const next_row, const next_col = new_pos.cast();
                elem = keypad_str[next_row][next_col];
                if (elem == ' ') continue;
                var new_path = state.path;
                try new_path.append(dir);

                try stack.append(.{
                    .position = new_pos,
                    .visited = new_visited,
                    .path = new_path,
                    .max_steps = state.max_steps,
                    .to_visit = state.to_visit,
                });
            }
        }
    }
    return shortest_path;
}

fn robots(allocator: Allocator, level: u8, path: []const u8, memo: *Set) !u64 {
    const State = struct {
        position: u8,
        visited: VisitedBuf,
        path: VisitedBuf,
    };
    const key: Key = .{ .level = level, .path = path };
    if (memo.*.get(key)) |value| return value;
    if (level == 0) return path.len;

    var position: u8 = 'A';
    var path_len: u64 = 0;
    var stack = std.ArrayList(State).init(allocator);
    defer stack.deinit();

    for (path) |next_pos| {
        var min_len: u64 = std.math.maxInt(u64);

        try stack.append(.{
            .position = position,
            .visited = VisitedBuf.init(),
            .path = VisitedBuf.init(),
        });

        while (stack.items.len != 0) {
            var state = stack.pop();

            if (state.position == next_pos) {
                var new_path = state.path;
                try new_path.append('A');
                const result = try robots(allocator, level - 1, new_path.getSlice(), memo);
                if (result < min_len) min_len = result;
                continue;
            }

            if (state.visited.contains(state.position)) continue;
            var new_vis = state.visited;
            try new_vis.append(state.position);

            for (dirpad(state.position)) |new_pos| {
                var new_path = state.path;
                try new_path.append(direction(state.position, new_pos));
                try stack.append(.{ .position = new_pos, .visited = new_vis, .path = new_path });
            }
        }

        path_len += min_len;
        position = next_pos;
    }

    const result = try memo.*.getOrPut(key);
    if (result.found_existing) {
        if (path_len < result.value_ptr.*) result.value_ptr.* = path_len;
    } else {
        const alloc_path = try allocator.alloc(u8, path.len);
        @memcpy(alloc_path, path);
        result.key_ptr.*.path = alloc_path;
        result.value_ptr.* = path_len;
    }

    return path_len;
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

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    const input_attributes = try myf.getInputAttributes(input);
    // End setup

    var memo = Set.init(allocator);
    defer {
        var keys = memo.keyIterator();
        while (keys.next()) |key| allocator.free(key.*.path);
        memo.deinit();
    }

    var p1_sum: u64 = 0;
    var p2_sum: u64 = 0;

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        const numeric: u64 = try std.fmt.parseInt(u64, row[0 .. row.len - 1], 10);
        p1_sum += numeric * try keypad(allocator, row, 2, &memo);
        p2_sum += numeric * try keypad(allocator, row, 25, &memo);
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}
