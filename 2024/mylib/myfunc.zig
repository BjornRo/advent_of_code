const std = @import("std");
const Allocator = std.mem.Allocator;
const Type = std.builtin.Type;

const DelimType = enum { CRLF, LF };

pub inline fn readFile(allocator: Allocator, filename: []u8) ![]u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    _ = try file.readAll(buffer);
    return buffer;
}

pub inline fn getAppArg(allocator: Allocator, index: usize) ![]u8 {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    return try std.mem.Allocator.dupe(allocator, u8, args[index]);
}

pub inline fn getDelimType(text: []const u8) !struct { delim: DelimType, row_len: u32 } {
    for (1..text.len - 1) |i| {
        if (text[i] == '\n') {
            const delim = if (text[i - 1] == '\r') DelimType.CRLF else DelimType.LF;
            return .{ .delim = delim, .row_len = @intCast(if (delim == .CRLF) i - 1 else i) };
        }
    }
    return error.NoDelimFound;
}

pub inline fn getInputAttributes(text: []const u8) !struct { delim: [:0]const u8, row_len: u32 } {
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

pub inline fn getNeighborOffset(comptime T: type) [4][2]T {
    comptime switch (@typeInfo(T)) {
        .Int, .ComptimeInt => {},
        else => unreachable,
    };
    return [4][2]T{ .{ 1, 0 }, .{ 0, 1 }, .{ -1, 0 }, .{ 0, -1 } };
}

pub inline fn getNextPositions(comptime T: type, row: T, col: T) [4][2]T {
    comptime switch (@typeInfo(T)) {
        .Int, .ComptimeInt => {},
        else => unreachable,
    };
    const a = @Vector(8, T){ row, col, row, col, row, col, row, col };
    const b = @Vector(8, T){ 1, 0, 0, 1, -1, 0, 0, -1 };
    const res: [8]T = a + b;
    return @as([4][2]T, @bitCast(res));
}

pub inline fn checkInBounds(comptime T: type, pos: [2]T, max_row: T, max_col: T) ?[2]usize {
    const row, const col = pos;
    if (0 <= row and row < max_row and 0 <= col and col < max_col)
        return .{ @intCast(row), @intCast(col) };
    return null;
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
        inline fn f(x: *T, y: *T, xu: *T, xv: *T, yu: *T, yv: *T) void {
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
