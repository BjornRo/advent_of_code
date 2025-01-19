const std = @import("std");
const Allocator = std.mem.Allocator;
const Type = std.builtin.Type;

const DelimType = enum { CRLF, LF };

pub fn FixedBuffer(comptime T: type, size: u16) type {
    return struct {
        buf: [size]T,
        len: @TypeOf(size) = 0,

        const Self = @This();

        pub fn initDefaultValue(value: T) Self {
            var item = Self{ .len = 0, .buf = undefined };
            for (0..size) |i| item.buf[i] = value;
            return item;
        }
        pub fn init() Self {
            return .{ .len = 0, .buf = undefined };
        }
        pub fn append(self: *Self, item: T) !void {
            if (self.len >= size) return error.Full;
            self.buf[self.len] = item;
            self.len += 1;
        }
        pub fn getSlice(self: *const Self) []T {
            return self.buf[0..self.len];
        }
        pub fn get(self: *const Self, index: u8) !T {
            if (index >= size) return error.OutOfBounds;
            return self.buf[index];
        }
        pub fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            defer self.len -= 1;
            return self.buf[self.len];
        }
        pub fn set(self: *Self, index: u8, value: T) !void {
            if (index >= size) return error.OutOfBounds;
            self.buf[index] = value;
        }
        pub fn contains(self: *const Self, value: T) bool {
            for (0..self.len) |i| if (self.buf[i] == value) return true;
            return false;
        }
        pub fn isFull(self: *const Self) bool {
            return self.len == size;
        }
    };
}

pub fn readFile(allocator: Allocator, filename: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    _ = try file.readAll(buffer);
    return buffer;
}

pub fn getAppArg(allocator: Allocator, index: usize) ![]u8 {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    return try std.mem.Allocator.dupe(allocator, u8, args[index]);
}

pub fn getDelimType(text: []const u8) !struct { delim: DelimType, row_len: u32 } {
    for (1..text.len - 1) |i| {
        if (text[i] == '\n') {
            const delim = if (text[i - 1] == '\r') DelimType.CRLF else DelimType.LF;
            return .{ .delim = delim, .row_len = @intCast(if (delim == .CRLF) i - 1 else i) };
        }
    }
    return error.NoDelimFound;
}

pub fn getInputAttributes(text: []const u8) !struct { delim: [:0]const u8, row_len: u32 } {
    for (1..text.len) |i| {
        if (text[i] == '\n') {
            const crlf: bool = text[i - 1] == '\r';
            return .{
                .delim = if (crlf) "\r\n" else "\n",
                .row_len = @intCast(if (crlf) i - 1 else i),
            };
        }
    }
    return error.NoDelimFound;
}

pub fn getNeighborOffset(comptime T: type) [4][2]T {
    comptime switch (@typeInfo(T)) {
        .Int, .ComptimeInt => {},
        else => unreachable,
    };
    return .{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
}

pub fn collect(comptime T: type, allocator: Allocator, iter_ptr: anytype) !std.ArrayList(T) {
    var list = std.ArrayList(T).init(allocator);
    while (iter_ptr.*.next()) |val| try list.append(val);
    return list;
}

pub fn getNextPositions(row: anytype, col: anytype) [4][2]@TypeOf(row, col) {
    const T = @TypeOf(row, col);
    comptime switch (@typeInfo(T)) {
        .Int, .ComptimeInt => {},
        else => unreachable,
    };
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

pub fn checkInBounds(comptime T: type, pos: [2]T, max_row: T, max_col: T) ?struct { row: usize, col: usize } {
    const row, const col = pos;
    if (0 <= row and row < max_row and 0 <= col and col < max_col)
        return .{ .row = @intCast(row), .col = @intCast(col) };
    return null;
}

pub fn all(slice: []const bool) bool {
    for (slice) |v| if (!v) return false;
    return true;
}

pub fn any(slice: []const bool) bool {
    for (slice) |v| if (v) return true;
    return false;
}

pub fn sum(slice: anytype) @TypeOf(slice[0]) {
    switch (@typeInfo(@TypeOf(slice))) {
        .Pointer => {},
        else => @compileError("Not a slice"),
    }
    var total: @TypeOf(slice[0]) = 0;
    for (slice) |v| total += v;
    return total;
}

pub fn average(slice: anytype) f64 {
    switch (@typeInfo(@TypeOf(slice))) {
        .Pointer => {},
        else => @compileError("Not a slice"),
    }
    const N: f64 = @floatFromInt(slice.len);
    var total: f64 = 0;
    for (slice) |v| total += v;
    return total / N;
}

pub fn product(slice: anytype) @TypeOf(slice[0]) {
    switch (@typeInfo(@TypeOf(slice))) {
        .Pointer => {},
        else => @compileError("Not a slice"),
    }
    var total: @TypeOf(slice[0]) = 1;
    for (slice) |v| total *= v;
    return total;
}

pub fn manhattan(a: anytype, b: anytype) u32 {
    switch (@typeInfo(@TypeOf(a[1], b[1]))) {
        .Int => |int| {
            if (int.signedness == .unsigned) {
                const x1: i32 = @intCast(a[0]);
                const y1: i32 = @intCast(a[1]);
                const x2: i32 = @intCast(b[0]);
                const y2: i32 = @intCast(b[1]);
                return @abs(x1 - y1) + @abs(x2 - y2);
            }
        },
        else => @compileError("Not a slice"),
    }
    return @intCast(@abs(a[0] - b[0]) + @abs(a[1] - b[1]));
}

pub fn euclidean(a: anytype, b: anytype) f64 {
    const T = @TypeOf(a[0], b[0]);
    switch (@typeInfo(T)) {
        .Float => {},
        .Int => {
            const x1: f64 = @floatFromInt(a[0]);
            const y1: f64 = @floatFromInt(a[1]);
            const x2: f64 = @floatFromInt(b[0]);
            const y2: f64 = @floatFromInt(b[1]);
            return @sqrt(std.math.pow(f64, x1 - y1, 2) +
                std.math.pow(f64, x2 - y2, 2));
        },
        else => @compileError("Not a slice"),
    }

    return @sqrt(std.math.pow(T, a[0] - b[0], 2) + std.math.pow(T, a[1] - b[1], 2));
}

pub fn rotateRight(comptime T: type, v: [2]T) [2]T {
    comptime switch (@typeInfo(T)) {
        .Int => |int| std.debug.assert(int.signedness == .signed),
        .ComptimeInt => {},
        else => unreachable,
    };
    return .{ v[1], -v[0] };
}

pub fn rotateLeft(comptime T: type, v: [2]T) [2]T {
    comptime switch (@typeInfo(T)) {
        .Int => |int| std.debug.assert(int.signedness == .signed),
        .ComptimeInt => {},
        else => unreachable,
    };
    return .{ -v[1], v[0] };
}

pub fn lcm(a: anytype, b: anytype) @TypeOf(a, b) {
    comptime switch (@typeInfo(@TypeOf(a, b))) {
        .Int => |int| std.debug.assert(int.signedness == .unsigned),
        .ComptimeInt => {
            std.debug.assert(a >= 0);
            std.debug.assert(b >= 0);
        },
        else => unreachable,
    };
    return @abs(a * b) / std.math.gcd(a, b);
}

pub fn egcd(comptime T: type, a: T, b: T) struct { gcd: T, u: T, v: T } {
    comptime switch (@typeInfo(T)) {
        .Int => |int| std.debug.assert(int.signedness == .signed),
        else => unreachable,
    };
    const F = struct {
        fn f(x: *T, y: *T, xu: *T, xv: *T, yu: *T, yv: *T) void {
            const Vec3 = @Vector(3, T);
            const new_vec_x = Vec3{ y.*, yu.*, yv.* } - Vec3{ x.*, xu.*, xv.* };
            y.* = x.*;
            yu.* = xu.*;
            yv.* = xv.*;
            x.* = new_vec_x[0];
            xu.* = new_vec_x[1];
            xv.* = new_vec_x[2];
        }
    };

    var _a: T = a;
    var _b: T = b;
    var au: T = 1;
    var av: T = 0;
    var bu: T = 0;
    var bv: T = 1;

    while (@mod(_a, _b) != 0 and @mod(_b, _a) != 0) {
        if (_a <= _b) {
            F.f(&_a, &_b, &au, &av, &bu, &bv);
        } else {
            F.f(&_b, &_a, &bu, &bv, &au, &av);
        }
    }

    return if (_a <= _b) .{ .gcd = _a, .u = au, .v = av } else .{ .gcd = _b, .u = bu, .v = bv };
}

pub fn modInverse(comptime T: type, a: T, m: T) !T {
    const res = egcd(T, a, m);
    if (res.gcd == 1) {
        return @mod(res.u, m);
    }
    return error.NoInverseExist;
}

pub fn crt(comptime T: type, remainders: []const T, moduli: []const T) !i128 {
    comptime switch (@typeInfo(T)) {
        .Int => |int| std.debug.assert(int.signedness == .signed),
        else => unreachable,
    };
    if (moduli.len != remainders.len) {
        return error.LengthMisMatch;
    }
    var prod: i128 = 1;
    for (moduli) |m| {
        prod *= m;
    }
    var result: i128 = 0;
    for (moduli, 0..) |mi, i| {
        const bi = @divExact(prod, mi);
        result += remainders[i] * (try modInverse(i128, bi, mi)) * bi;
    }
    return @mod(result, prod);
}

pub fn variance(slice: anytype) f64 {
    switch (@typeInfo(@TypeOf(slice))) {
        .Pointer => {},
        else => @compileError("Not a slice"),
    }
    const n: f64 = @floatFromInt(slice.len);
    if (n == 0) return 0.0;

    const mean = average(slice);

    var sqDiff: f64 = 0.0;
    for (slice) |value| {
        const diff = value - mean;
        sqDiff += diff * diff;
    }
    return sqDiff / n;
}

pub fn concatInts(comptime T: type, a: T, b: T) T {
    const digits_b = if (b == 0) 1 else std.math.log10_int(b) + 1;
    return a * (std.math.powi(T, 10, digits_b) catch unreachable) + b;
}

pub fn scaleMatrix(alloc: Allocator, matrix: anytype, scale: u8) ![][]@TypeOf(matrix[0][0]) {
    const T = @TypeOf(matrix[0][0]);
    const row_len = matrix.len;
    const col_len = matrix[0].len;
    var new_matrix = try alloc.alloc([]T, row_len * scale);

    for (0..row_len * scale) |i| {
        new_matrix[i] = try alloc.alloc(T, col_len * scale);
        const source_row = i / scale;
        for (0..(col_len * scale)) |j| {
            const source_col = j / scale;
            new_matrix[i][j] = matrix[source_row][source_col];
        }
    }

    return new_matrix;
}

pub fn expandMatrix3x(comptime T: type, alloc: Allocator, matrix: []const []const T) ![][]T {
    const row_len = matrix.len;
    const col_len = matrix[0].len;
    var new_matrix = try alloc.alloc([]T, row_len * 3);

    for (0..row_len * 3) |i| {
        new_matrix[i] = try alloc.alloc(T, col_len * 3);
        const source_row = i / 3;
        for (0..(col_len * 3)) |j| {
            const source_col = j / 3;
            new_matrix[i][j] = matrix[source_row][source_col];
        }
    }

    return new_matrix;
}

pub fn sortMat(comptime T: type, mat: [][]T, comptime asc: bool) void {
    const Cmp = struct {
        fn lt(_: void, lhs: []T, rhs: []T) bool {
            return std.mem.order(T, lhs, rhs) == .lt;
        }
        fn gt(_: void, lhs: []T, rhs: []T) bool {
            return std.mem.order(T, lhs, rhs) == .gt;
        }
    };
    std.mem.sort([]T, mat, {}, if (asc) Cmp.lt else Cmp.gt);
}

pub fn reversed(array: anytype) void {
    switch (@typeInfo(@TypeOf(array))) {
        .Pointer => {},
        else => @compileError("`reversed` only accepts slices."),
    }
    var i = array.len - 1;
    var j: @TypeOf(array.len) = 0;
    while (i > j) {
        const temp = array[i];
        array[i] = array[j];
        array[j] = temp;
        i -= 1;
        j += 1;
    }
}

pub fn flip(matrix: anytype) void {
    if (@typeInfo(@TypeOf(matrix)) != .Pointer and @typeInfo(@TypeOf(matrix[0])) != .Pointer) {
        @compileError("`flip` only accepts matrices.");
    }
    for (matrix) |row| {
        reversed(row);
    }
}

pub fn transpose_mut(allocator: Allocator, matrix: anytype) !void {
    if (@typeInfo(@TypeOf(matrix)).Pointer.size != Type.Pointer.Size.One and
        @typeInfo(@TypeOf(matrix[0])) != .Pointer)
    {
        @compileError("`transpose` only accepts matrices given outer pointer.");
    }
    const oldMatrix = matrix.*;
    const numRows = oldMatrix.len;
    const numCols = oldMatrix[0].len;
    var newMatrix = try allocator.alloc(@TypeOf(oldMatrix[0]), numCols);
    defer allocator.free(oldMatrix);

    for (0..numCols) |i| {
        newMatrix[i] = try allocator.alloc(@TypeOf(oldMatrix[0][0]), numRows);
    }
    for (oldMatrix, 0..) |row, i| {
        for (row, 0..) |value, j| {
            newMatrix[j][i] = value;
        }
        allocator.free(row);
    }
    matrix.* = newMatrix;
}

pub fn transpose(comptime T: type, allocator: Allocator, matrix: []const []const T) ![][]T {
    const numRows = matrix.len;
    const numCols = matrix[0].len;
    printAny(numCols);
    printAny(numRows);
    var newMatrix = try allocator.alloc([]T, numCols);
    for (newMatrix) |*row| row.* = try allocator.alloc(T, numRows);

    for (matrix, 0..) |row, i| {
        for (row, 0..) |value, j| newMatrix[j][i] = value;
    }
    return newMatrix;
}

pub fn padMatScalar(comptime T: type, alloc: Allocator, matrix: []const []const T, pad: T) ![][]T {
    const row_len = matrix.len;
    const col_len = matrix[0].len;
    var new_matrix = try alloc.alloc([]T, row_len + 2);

    for (1..row_len + 1) |i| {
        new_matrix[i] = try alloc.alloc(T, col_len + 2);
        @memcpy(new_matrix[i][1 .. col_len + 1], matrix[i - 1][0..col_len]);
        new_matrix[i][0] = pad;
        new_matrix[i][col_len + 1] = pad;
    }

    inline for (.{ 0, col_len + 1 }) |i| {
        new_matrix[i] = try alloc.alloc(T, col_len + 2);
        for (0..col_len + 2) |j| new_matrix[i][j] = pad;
    }
    return new_matrix;
}

pub fn copyMatrix(allocator: Allocator, matrix: anytype) ![][]@TypeOf(matrix[0][0]) {
    const T = @TypeOf(matrix[0][0]);
    const row_len = matrix[0].len;
    const new_matrix = try allocator.alloc([]T, matrix.len);
    for (matrix, 0..) |row, i| {
        new_matrix[i] = try allocator.alloc(T, row_len);
        @memcpy(new_matrix[i], row);
    }

    return new_matrix;
}

pub fn initValueSlice(allocator: Allocator, length: usize, value: anytype) ![]@TypeOf(value) {
    const T = @TypeOf(value);
    const slice = try allocator.alloc(T, length);
    for (slice) |*c| c.* = value;
    return slice;
}

pub fn initValueMatrix(allocator: Allocator, rows: usize, cols: usize, value: anytype) ![][]@TypeOf(value) {
    const T = @TypeOf(value);
    const matrix = try allocator.alloc([]T, rows);
    for (matrix) |*row| {
        row.* = try allocator.alloc(T, cols);
        for (row.*) |*c| c.* = value;
    }

    return matrix;
}

pub fn freeMatrix(allocator: Allocator, matrix: anytype) void {
    for (matrix) |row| allocator.free(row);
    allocator.free(matrix);
}

pub fn printMat(comptime T: type, matrix: [][]const T, offset: u16) void {
    const stdout = std.io.getStdOut().writer();
    for (matrix) |arr| {
        for (arr) |elem| {
            const typeInfo = @typeInfo(T);
            const val = switch (typeInfo) {
                .Enum => @intFromEnum(elem),
                else => elem,
            };
            // @as(@TypeOf(val), @intCast(offset))
            stdout.print("{d} ", .{val - offset}) catch {};
        }
        stdout.print("\n", .{}) catch {};
    }
    stdout.print("\n", .{}) catch {};
}

pub fn printMatStr(matrix: []const []const u8) void {
    const stdout = std.io.getStdOut().writer();
    for (matrix) |row| stdout.print("{s}\n", .{row}) catch {};
    stdout.print("\n", .{}) catch {};
}

pub inline fn printAny(n: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{any}\n", .{n}) catch {};
}

pub inline fn printStr(n: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}\n", .{n}) catch {};
}

pub fn waitForInput() void {
    const stdin = std.io.getStdIn().reader();
    while (true) {
        const res = stdin.readByte() catch return;
        if (res == '\n') return;
    }
}

pub fn slowDown(ms: usize) void {
    std.time.sleep(ms * 1_000_000);
}

pub fn joinStrings(allocator: Allocator, strings: anytype, separator: []const u8) ![]const u8 {
    var list = std.ArrayList(u8).init(allocator);

    for (strings) |str| {
        for (str) |c| try list.append(c);
        for (separator) |c| try list.append(c);
    }
    list.items.len -= separator.len;
    return list.toOwnedSlice();
}

// pub fn ValidNeighborsIterator(comptime T: type) type {
//     return struct {
//         positions: []const [2]T,
//         min_pos: T,
//         max_row: T,
//         max_col: T,
//         index: usize,

//         const Self = @This();

//         pub fn next(self: *Self) ?[2]T {
//             while (self.index < self.positions.len) {
//                 const nrow, const ncol = self.positions[self.index];
//                 if (self.min_pos <= nrow and nrow < self.max_row and
//                     self.min_pos <= ncol and ncol < self.max_col)
//                 {
//                     defer self.index += 1;
//                     return self.positions[self.index];
//                 }
//                 self.index += 1;
//             }
//             return null;
//         }
//     };
// }
// pub fn validNeighborsIter(
//     comptime slice: anytype,
//     min_pos: @TypeOf(slice[0][0]),
//     max_row: @TypeOf(slice[0][0]),
//     max_col: @TypeOf(slice[0][0]),
// ) ValidNeighborsIterator(@TypeOf(slice[0][0])) {
//     return .{
//         .positions = &slice,
//         .min_pos = min_pos,
//         .max_row = max_row,
//         .max_col = max_col,
//         .index = 0,
//     };
// }

// pub fn ValidScalarNeighborsIterator(comptime T: type, comptime S: type) type {
//     return struct {
//         invalid_scalar: S,
//         matrix: []const []const S,
//         index: usize,
//         positions: []const [2]T,

//         const Self = @This();

//         pub fn next(self: *Self) ?struct { pos: [2]T, elem: S } {
//             while (self.index < self.positions.len) {
//                 const nrow, const ncol = self.positions[self.index];
//                 const elem = self.matrix[@intCast(nrow)][@intCast(ncol)];
//                 if (elem != self.invalid_scalar) {
//                     defer self.index += 1;
//                     return .{ .pos = self.positions[self.index], .elem = elem };
//                 }
//                 self.index += 1;
//             }
//             return null;
//         }
//     };
// }
// pub fn validScalarNeighborsIterator(
//     comptime slice: anytype,
//     invalid_scalar: anytype,
//     matrix: anytype,
// ) ValidNeighborsIterator(@TypeOf(slice[0][0]), @TypeOf(invalid_scalar)) {
//     return .{
//         .invalid_scalar = invalid_scalar,
//         .matrix = matrix,
//         .index = 0,
//         .positions = &slice,
//     };
// }
