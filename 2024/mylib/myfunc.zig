const std = @import("std");
const Allocator = std.mem.Allocator;
const Type = std.builtin.Type;

const DelimType = enum { CRLF, LF };

pub fn readFile(allocator: Allocator, filename: []u8) ![]u8 {
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

pub fn ValidNeighborsIterator(comptime T: type, comptime P: type) type {
    return struct {
        positions: P,
        min_pos: T,
        max_row: T,
        max_col: T,
        index: usize,

        const Self = @This();

        pub fn next(self: *Self) ?[2]T {
            while (self.index < self.positions.len) {
                const nrow, const ncol = self.positions[self.index];
                if (self.min_pos <= nrow and nrow < self.max_row and
                    self.min_pos <= ncol and ncol < self.max_col)
                {
                    defer self.index += 1;
                    return self.positions[self.index];
                }
                self.index += 1;
            }
            return null;
        }
    };
}
pub fn validNeighborsIter(
    comptime slice: anytype,
    min_pos: @TypeOf(slice[0][0]),
    max_row: @TypeOf(slice[0][0]),
    max_col: @TypeOf(slice[0][0]),
) ValidNeighborsIterator(@TypeOf(slice[0][0]), @TypeOf(slice)) {
    return .{
        .positions = slice,
        .min_pos = min_pos,
        .max_row = max_row,
        .max_col = max_col,
        .index = 0,
    };
}

pub fn getNextPositions(comptime T: type, row: T, col: T) [4][2]T {
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
    switch (@typeInfo(@TypeOf(slice))) {
        .Pointer => {},
        else => @compileError("Not a slice"),
    }
    for (slice) |v| if (!v) return false;
    return true;
}

pub fn any(slice: []const bool) bool {
    switch (@typeInfo(@TypeOf(slice))) {
        .Pointer => {},
        else => @compileError("Not a slice"),
    }
    for (slice) |v| if (v) return true;
    return false;
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
    if (res[0] == 1) {
        return @mod(res[1], m);
    }
    return error.NoInverseExist;
}

pub fn crt(comptime T: type, moduli: []T, remainders: []T) !i128 {
    comptime switch (@typeInfo(T)) {
        .Int => |int| std.debug.assert(int.signedness == .signed),
        else => unreachable,
    };
    if (moduli.len != remainders.len) {
        return error.LengthMisMatch;
    }
    var product: i128 = 1;
    for (moduli) |m| {
        product *= m;
    }
    var result: i128 = 0;
    for (moduli, 0..) |mi, i| {
        const bi = @divExact(product, mi);
        result += remainders[i] * (try modInverse(i128, bi, mi)) * bi;
    }
    return @mod(result, product);
}

pub fn concatInts(comptime T: type, a: T, b: T) T {
    const digits_b = std.math.log10_int(b) + 1;
    return a * (std.math.powi(T, 10, digits_b) catch unreachable) + b;
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

pub fn transpose(allocator: Allocator, matrix: anytype) !void {
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

pub inline fn printAny(n: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{any}\n", .{n}) catch {};
}

pub inline fn printStr(n: anytype) void {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}\n", .{n}) catch {};
}
