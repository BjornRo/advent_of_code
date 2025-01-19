const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const expect = std.testing.expect;
const Allocator = std.mem.Allocator;

const ProgT = i64;
const CT = i16;

const Point = struct {
    row: CT,
    col: CT,

    const Self = @This();
    fn init(row: CT, col: CT) Self {
        return .{ .row = row, .col = col };
    }
    fn initA(arr: [2]CT) Self {
        return .{ .row = arr[0], .col = arr[1] };
    }
    fn add(self: Self, o: Point) Point {
        return Self.init(self.row + o.row, self.col + o.col);
    }
    fn mul(self: Point, other: Point) Point {
        return Point.init(
            self.row * other.row - self.col * other.col,
            self.row * other.col + self.col * other.row,
        );
    }
    fn cast(self: Self) [2]u16 {
        return .{ @intCast(self.row), @intCast(self.col) };
    }
};

const CharIterator = struct {
    str: []const u8,
    index: usize = 0,

    fn next(self: *CharIterator) ?u8 {
        if (self.index >= self.str.len) return null;
        defer self.index += 1;
        return self.str[self.index];
    }
};

const Machine = struct {
    registers: std.ArrayList(ProgT),
    input_value: ?CharIterator = null,
    relative_base: ProgT = 0,
    pc_value: ProgT = 0,
    pc: u32 = 0,

    const Self = @This();

    pub fn init(registers: std.ArrayList(ProgT), register_size: usize) !Machine {
        var regs = registers;
        for (0..register_size - registers.items.len) |_| try regs.append(0);
        return Machine{ .registers = regs };
    }

    fn get_factor(param: u32) ProgT {
        return @intCast((std.math.powi(ProgT, 10, param) catch unreachable) * 10);
    }

    fn set_pc_value_get_op(self: *Self) ProgT {
        self.pc_value = self.registers.items[@intCast(self.pc)];
        return @mod(self.pc_value, 100);
    }

    fn get_value(self: *Self, param: u32, add_pc: u32) ProgT {
        const offset = self.pc + param;
        const item = switch (@mod(@divFloor(self.registers.items[self.pc], get_factor(param)), 10)) {
            0 => self.registers.items[offset],
            1 => offset,
            else => self.relative_base + self.registers.items[offset],
        };
        self.pc += add_pc;
        return self.registers.items[@intCast(item)];
    }

    fn set_value(self: *Self, param: u32, put_value: ProgT) void {
        const item = self.registers.items[self.pc + param];
        const index = switch (@mod(@divFloor(self.registers.items[self.pc], get_factor(param)), 10)) {
            0 => item,
            else => self.relative_base + item,
        };
        self.pc += param + 1;
        self.registers.items[@intCast(index)] = put_value;
    }

    pub fn run(self: *Self) ?ProgT {
        while (true) {
            switch (self.set_pc_value_get_op()) {
                1 => self.set_value(3, self.get_value(1, 0) + self.get_value(2, 0)),
                2 => self.set_value(3, self.get_value(1, 0) * self.get_value(2, 0)),
                3 => self.set_value(1, self.input_value.?.next().?),
                4 => return self.get_value(1, 2),
                5 => self.pc = if (self.get_value(1, 0) != 0) @intCast(self.get_value(2, 0)) else self.pc + 3,
                6 => self.pc = if (self.get_value(1, 0) == 0) @intCast(self.get_value(2, 0)) else self.pc + 3,
                7 => self.set_value(3, if (self.get_value(1, 0) < self.get_value(2, 0)) 1 else 0),
                8 => self.set_value(3, if (self.get_value(1, 0) == self.get_value(2, 0)) 1 else 0),
                9 => self.relative_base += self.get_value(1, 2),
                else => return null, // 99
            }
        }
    }
};

fn part1(allocator: Allocator, registers: *const std.ArrayList(ProgT)) !struct { p1_result: usize, matrix: [][]u8 } {
    var machine = try Machine.init(try registers.*.clone(), 4000);
    var linear_matrix = std.ArrayList(u8).init(allocator);
    defer inline for (.{ machine.registers, linear_matrix }) |x| x.deinit();

    while (machine.run()) |value| try linear_matrix.append(@intCast(@as(i8, @truncate(value))));

    var matrix = blk: {
        const line_len_newline = std.mem.indexOfScalar(u8, linear_matrix.items, '\n').? + 1;
        const lines = (linear_matrix.items.len - 1) / line_len_newline;
        var matrix = try myf.initValueMatrix(allocator, lines + 2, line_len_newline + 1, @as(u8, '.'));
        var lm_it = std.mem.tokenizeScalar(u8, linear_matrix.items, '\n');
        var i: u8 = 1;
        while (lm_it.next()) |row| {
            for (row, 1..) |e, j| matrix[i][j] = e;
            i += 1;
        }
        break :blk matrix;
    };

    var sum: usize = 0;
    for (1..matrix.len - 1) |i| {
        for (1..matrix[0].len - 1) |j| {
            if (matrix[i][j] != '#') continue;
            const ii: i8 = @intCast(i);
            const jj: i8 = @intCast(j);
            var count: u8 = 0;
            for (myf.getNextPositions(ii, jj)) |pos| {
                const row, const col = pos;
                if (matrix[@intCast(row)][@intCast(col)] == '#') count += 1;
            }
            if (count == 4) {
                matrix[i][j] = 'O';
                sum += (i - 1) * (j - 1);
            }
        }
    }
    return .{ .p1_result = sum, .matrix = matrix };
}

fn findStrings(allocator: Allocator, string: []const u8, index: u8, sub_strings: *[3][]const u8) !bool {
    if (index == sub_strings.len) {
        for (string) |s| if (s != ',') return false;
        for (sub_strings) |*s| s.* = try allocator.dupe(u8, s.*);
        return true;
    }
    const end = @min(21, string.len);
    for (0..end) |i| {
        const j = end - i - 1;
        if (j <= 2) return false;
        if (string[j] == ',' or !std.ascii.isDigit(string[j])) continue;

        const sub_string = try std.mem.replaceOwned(u8, allocator, string, string[0 .. j + 1], "");
        defer allocator.free(sub_string);
        if (sub_string.len == string.len - j + 1) continue;

        sub_strings[index] = string[0 .. j + 1];
        if (try findStrings(allocator, std.mem.trimLeft(u8, sub_string, ","), index + 1, sub_strings)) return true;
    }
    return false;
}

fn part2(allocator: Allocator, matrix: []const []const u8, registers: *const std.ArrayList(ProgT)) !ProgT {
    var input_list = std.ArrayList(u8).init(allocator);
    var machine = try Machine.init(try registers.clone(), 4000);
    defer inline for (.{ machine.registers, input_list }) |x| x.deinit();

    var pos: Point, var dir: Point = outer: for (0..matrix.len) |i| {
        for (0..matrix[0].len) |j|
            switch (matrix[i][j]) {
                '^', '<', '>', 'v' => |c| {
                    const dir = switch (c) {
                        '^' => Point.init(-1, 0),
                        '<' => Point.init(0, -1),
                        '>' => Point.init(0, 1),
                        else => Point.init(1, 0),
                    };
                    break :outer [2]Point{ Point.init(@intCast(i), @intCast(j)), dir };
                },
                else => {},
            };
    } else unreachable;

    while (true) {
        if (input_list.items.len != 0) {
            var count: u8 = 0;
            for (myf.getNextPositions(pos.row, pos.col)) |np| {
                const row, const col = Point.initA(np).cast();
                if (matrix[row][col] == '.') count += 1;
            }
            if (count == 3) {
                _ = input_list.pop();
                break;
            }
        }

        for ([2]Point{ Point.init(0, 1), Point.init(0, -1) }, [2]u8{ 'L', 'R' }) |rot, symbol| {
            const new_dir = dir.mul(rot);
            const row, const col = pos.add(new_dir).cast();
            if (matrix[row][col] == '#') {
                dir = new_dir;
                try input_list.append(symbol);
                try input_list.append(',');
                break;
            }
        } else unreachable;

        var steps: u8 = 0;
        while (true) {
            const next_pos = pos.add(dir);
            const row, const col = next_pos.cast();
            if (matrix[row][col] == '.') {
                if (steps >= 10) {
                    try input_list.append(steps / 10 + '0');
                    steps %= 10;
                }
                try input_list.append(steps + '0');
                try input_list.append(',');
                break;
            }
            steps += 1;
            pos = next_pos;
        }
    }

    var main_routine = try allocator.dupe(u8, input_list.items);
    defer allocator.free(main_routine);

    var strings: [3][]u8 = undefined;
    if (!try findStrings(allocator, input_list.items, 0, &strings)) unreachable;
    defer for (strings) |s| allocator.free(s);

    for (strings, [3][]const u8{ "A", "B", "C" }) |s, c| {
        const new_routine = try std.mem.replaceOwned(u8, allocator, main_routine, s, c);
        allocator.free(main_routine);
        main_routine = new_routine;
    }

    const final_string = blk: {
        var list = std.ArrayList([]const u8).init(allocator);
        defer list.deinit();
        try list.append(main_routine);
        for (strings) |s| try list.append(s);
        inline for (.{ "n", "" }) |s| try list.append(s);
        break :blk try std.mem.join(allocator, "\n", list.items);
    };
    defer allocator.free(final_string);

    machine.registers.items[0] = 2;
    machine.input_value = CharIterator{ .str = final_string };

    return while (machine.run()) |res| {
        if (res >= 128) break res;
    } else 0;
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
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
    // End setup

    var registers = std.ArrayList(ProgT).init(allocator);
    defer registers.deinit();

    var in_iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\r\n"), ',');
    while (in_iter.next()) |raw_value| try registers.append(try std.fmt.parseInt(ProgT, raw_value, 10));

    const result = try part1(allocator, &registers);
    defer myf.freeMatrix(allocator, result.matrix);

    // for (result.matrix) |row| prints(row);
    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        result.p1_result,
        try part2(allocator, result.matrix, &registers),
    });
}
