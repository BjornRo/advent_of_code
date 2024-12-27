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
        return std.hash.CityHash64.hash(key.path) + key.level;
    }
    pub fn eql(_: @This(), a: Key, b: Key) bool {
        return a.level == b.level and std.mem.eql(u8, a.path, b.path);
    }
};

const Set = std.HashMap(Key, u64, HashCtx, 90);

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
        return @intCast(myf.manhattan(self.toArr(), p.toArr()));
    }
    fn addA(self: Self, arr: [2]CT) Point {
        return .{
            .row = self.row + arr[0],
            .col = self.col + arr[1],
        };
    }
};

const keypad_matrix = [4]*const [3:0]u8{
    "789",
    "456",
    "123",
    "B0A",
};

const rows: i8 = keypad_matrix.len;
const cols: i8 = keypad_matrix[0].len;

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

fn getKeypadPoint(char: u8) Point {
    return switch (char) {
        '7' => Point.init(0, 0),
        '8' => Point.init(0, 1),
        '9' => Point.init(0, 2),
        '4' => Point.init(1, 0),
        '5' => Point.init(1, 1),
        '6' => Point.init(1, 2),
        '1' => Point.init(2, 0),
        '2' => Point.init(2, 1),
        '3' => Point.init(2, 2),
        '0' => Point.init(3, 1),
        'A' => Point.init(3, 2),
        else => unreachable,
    };
}

fn keypad(allocator: Allocator, input_row: []const u8, n_robots: u8, memo: *Set) !u64 {
    const State = struct {
        position: Point,
        visited: VisitedBuf,
        path: PathBuf,
        max_steps: i8,
        to_visit: []const u8,
    };

    var shortest_path: u64 = std.math.maxInt(u64);

    var stack = std.ArrayList(State).init(allocator);
    defer stack.deinit();
    try stack.append(.{
        .position = getKeypadPoint('A'),
        .visited = VisitedBuf.init(),
        .path = PathBuf.init(),
        .max_steps = getKeypadPoint('A').manhattan(getKeypadPoint(input_row[0])),
        .to_visit = input_row,
    });

    while (stack.items.len != 0) {
        var state = stack.pop();
        const row, const col = state.position.cast();
        var elem = keypad_matrix[row][col];
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
                .max_steps = getKeypadPoint(state.to_visit[0]).manhattan(getKeypadPoint(state.to_visit[1])),
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
                elem = keypad_matrix[next_row][next_col];
                if (elem == 'B') continue;
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
    var buffer: [200_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

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
        p2_sum += numeric * try keypad(allocator, row, 25, &memo); // P1 is essentially a lookup.
        p1_sum += numeric * try keypad(allocator, row, 2, &memo);
    }

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{ p1_sum, p2_sum });
}
