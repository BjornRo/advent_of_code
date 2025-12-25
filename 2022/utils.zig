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
    };
}

pub const Matrix = struct {
    data: []u8,
    rows: usize,
    cols: usize,
    stride: usize,

    pub fn get(self: *Matrix, row: usize, col: usize) u8 {
        return self.data[row * self.stride + col];
    }
    pub fn set(self: *Matrix, row: usize, col: usize, value: u8) void {
        self.data[row * self.stride + col] = value;
    }
    pub fn inBounds(self: *Matrix, row: isize, col: isize) bool {
        const maxRows: isize = @intCast(self.rows);
        const maxCols: isize = @intCast(self.cols);
        return 0 <= row and row < maxRows and 0 <= col and col < maxCols;
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
