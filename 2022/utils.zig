const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn read(alloc: Allocator, file_name: []const u8) ![]u8 {
    var fd = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
    defer fd.close();

    const file_size = try fd.getEndPos();

    const buffer = try alloc.alloc(u8, file_size);
    {
        var reader = fd.reader(buffer);
        try reader.interface.fill(file_size);
    }

    var i: usize = 0;
    for (buffer) |c| {
        if (c == '\r') continue;
        buffer[i] = c;
        i += 1;
    }
    if (buffer[i - 1] == '\n') i -= 1;
    if (i == file_size) return buffer;
    const mem = try alloc.alloc(u8, i);
    defer alloc.free(buffer);
    @memcpy(mem, buffer[0..i]);
    return mem;
}

pub fn sum(sequence: anytype) @TypeOf(sequence[0]) {
    var total: @TypeOf(sequence[0]) = 0;
    for (sequence) |i| total += i;
    return total;
}

inline fn swap(comptime T: type, a: *T, b: *T) void {
    const tmp = a.*;
    a.* = b.*;
    b.* = tmp;
}

pub fn permutate(comptime T: type, list: []T) PermutationIterator(T) {
    return PermutationIterator(T){
        .list = list[0..],
        .size = @intCast(list.len),
        .state = [_]u4{0} ** 16,
        .stateIndex = 0,
        .first = true,
    };
}

fn PermutationIterator(comptime T: type) type {
    return struct {
        list: []T,
        size: u4,
        state: [16]u4,
        stateIndex: u4,
        first: bool,

        const Self = @This();

        pub fn next(self: *Self) ?[]T {
            if (self.first) {
                self.first = false;
                return self.list;
            }

            while (self.stateIndex < self.size) {
                if (self.state[self.stateIndex] < self.stateIndex) {
                    if (self.stateIndex % 2 == 0) {
                        swap(T, &self.list[0], &self.list[self.stateIndex]);
                    } else {
                        swap(T, &self.list[self.state[self.stateIndex]], &self.list[self.stateIndex]);
                    }

                    self.state[self.stateIndex] += 1;
                    self.stateIndex = 0;

                    return self.list;
                } else {
                    self.state[self.stateIndex] = 0;
                    self.stateIndex += 1;
                }
            }

            return null;
        }
    };
}

pub fn firstNumber(comptime T: type, start: usize, str: []const u8) ?struct { end_index: usize, value: T } {
    var index: usize = start;
    while (index < str.len) : (index += 1) if ('0' <= str[index] and str[index] <= '9') break;
    if (index >= str.len) return null;
    var end = index + 1;
    while (end < str.len) : (end += 1) if (!('0' <= str[end] and str[end] <= '9')) break;
    return .{ .end_index = end, .value = std.fmt.parseInt(T, str[index..end], 10) catch unreachable };
}

pub fn NumberIter(comptime T: type) type {
    return struct {
        index: usize = 0,
        string: []const u8,
        pub fn next(self: *@This()) ?T {
            if (firstNumber(T, self.index, self.string)) |res| {
                self.index = res.end_index;
                return res.value;
            }
            return null;
        }
        pub fn init(string: []const u8) @This() {
            return .{ .index = 0, .string = string };
        }
    };
}

pub const HashMatrix = struct {
    const Val = i32;
    const Map = std.AutoHashMap(struct { Val, Val }, u8);
    data: Map,
    const Self = @This();
    pub fn init(alloc: Allocator) Self {
        return .{ .data = Map.init(alloc) };
    }
    pub fn deinit(self: *Self) void {
        self.data.deinit();
    }
    pub fn get(self: *Self, row: Val, col: Val) ?u8 {
        return self.data.get(.{ row, col });
    }
    pub fn set(self: *Self, row: Val, col: Val, value: u8) !void {
        try self.data.put(.{ row, col }, value);
    }
    pub fn add(self: *Self, row: Val, col: Val, value: u8) !bool {
        const res = try self.data.getOrPut(.{ row, col }, value);
        return !res.found_existing;
    }
    pub fn del(self: *Self, row: Val, col: Val) void {
        self.data.remove(.{ row, col });
    }
    pub fn contains(self: *Self, row: Val, col: Val) bool {
        return self.data.contains(.{ row, col });
    }
};

pub const Matrix = struct {
    data: []u8,
    rows: usize,
    cols: usize,
    stride: usize,

    const Self = @This();
    pub fn get(self: *Self, row: usize, col: usize) u8 {
        return self.data[row * self.stride + col];
    }
    pub fn set(self: *Self, row: usize, col: usize, value: u8) void {
        self.data[row * self.stride + col] = value;
    }
    pub fn inBounds(self: *Self, row: isize, col: isize) bool {
        const maxRows: isize = @intCast(self.rows);
        const maxCols: isize = @intCast(self.cols);
        return 0 <= row and row < maxRows and 0 <= col and col < maxCols;
    }
    pub fn empty(alloc: Allocator, rows: usize, cols: usize) !Self {
        const data = try alloc.alloc(u8, rows * cols);
        @memset(data, 0);
        return .{ .data = data, .rows = rows, .cols = cols, .stride = cols };
    }
    pub fn print(self: *Self, comptime default: u8) void {
        for (0..self.rows) |i| {
            for (0..self.cols) |j| {
                const elem = self.get(i, j);
                std.debug.print("{c}", .{if (elem != 0 and elem != default) elem else default});
            }
            std.debug.print("\n", .{});
        }
    }
};

pub fn arrayToMatrix(array: []u8) Matrix {
    var stride: usize = 0;
    var cols: usize = 0;
    var rows: usize = 1;

    for (array, 0..) |c, i|
        if (c == '\n') {
            stride = i + 1;
            cols = i;
            break;
        };

    for (array) |c| {
        if (c == '\n') rows += 1;
    }

    return Matrix{
        .data = array,
        .rows = rows,
        .cols = cols,
        .stride = stride,
    };
}

pub fn getNextPositions(row: anytype, col: anytype) [4][2]@TypeOf(row, col) {
    const T = @TypeOf(row, col);
    const a = @Vector(8, T){ row, col, row, col, row, col, row, col };
    const b = @Vector(8, T){ 1, 0, 0, 1, -1, 0, 0, -1 };
    const res: [8]T = a + b;
    return @bitCast(res);
}

pub fn getKernel3x3(comptime T: type, row: T, col: T) [8][2]T {
    comptime switch (@typeInfo(T)) {
        .Int, .ComptimeInt => {},
        else => unreachable,
    };
    const a = @Vector(16, T){ row, col, row, col, row, col, row, col, row, col, row, col, row, col, row, col };
    const b = @Vector(16, T){ 1, 0, 0, 1, -1, 0, 0, -1, -1, -1, -1, 1, 1, -1, 1, 1 };
    const res: [16]T = a + b;
    return @bitCast(res);
}

pub inline fn hashU64(key: u64) u64 {
    // https://nullprogram.com/blog/2018/07/31/
    var x = key;
    x ^= x >> 32;
    x *%= 0xd6e8feb86659fd93;
    x ^= x >> 32;
    x *%= 0xd6e8feb86659fd93;
    x ^= x >> 32;
    return x;
}

pub fn Repeat(comptime T: type) type {
    return struct {
        index: usize,
        sequence: []const T,

        const Self = @This();
        pub fn next(self: *Self) T {
            defer self.index = @mod(self.index + 1, self.sequence.len);
            return self.sequence[self.index];
        }
        pub fn init(sequence: []const T) Self {
            return .{ .index = 0, .sequence = sequence };
        }
    };
}

// const UnionFind = struct {
//     parent: []?usize,
//     rank: []?usize,

//     const Self = @This();
//     fn find(self: Self, id: usize) usize {
//         var p = self.parent[id] orelse id;
//         if (p != id) {
//             p = find(p);
//             self.parent[id] = p;
//         }
//         return p;
//     }
//     fn @"union"(self: Self, id1: usize, id2: usize) void {
//         const root1 = find(id1);
//         const root2 = find(id2);
//         if (root1 == root2) return;

//         const r1 = self.rank[root1] orelse 0;
//         const r2 = self.rank[root2] orelse 0;
//         if (r1 < r2) {
//             self.parent[root1] = root2;
//         } else if (r1 > r2) {
//             self.parent[root2] = root1;
//         } else {
//             self.parent[root2] = root1;
//             self.rank[root1] = r1 + 1;
//         }
//     }
//     fn init(alloc: Allocator, sequence: []Cube) !Self {
//         const new: Self = .{
//             .parent = try alloc.alloc(usize, sequence.len),
//             .rank = try alloc.alloc(usize, sequence.len),
//         };
//         for (sequence) |e| {
//             new.parent[e.id] = e.id;
//             new.rank[e.id] = 0;
//         }
//     }
//     fn deinit(self: Self, alloc: Allocator) void {
//         alloc.free(self.parent);
//         alloc.free(self.rank);
//     }
// };
