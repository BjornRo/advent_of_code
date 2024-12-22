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

const CT = i16;

const Point = struct {
    row: CT,
    col: CT,

    const Self = @This();

    fn initA(arr: [2]CT) Self {
        return .{ .row = arr[0], .col = arr[1] };
    }
    fn init(row: anytype, col: anytype) Self {
        return .{ .row = @intCast(row), .col = @intCast(col) };
    }
    fn cast(self: Self) [2]u16 {
        return .{ @intCast(self.row), @intCast(self.col) };
    }
    fn eq(self: Self, o: Point) bool {
        return self.row == o.row and self.col == o.col;
    }
    fn toArr(self: Self) [2]CT {
        return .{ self.row, self.col };
    }
    fn r(self: Self) u16 {
        return @intCast(self.row);
    }
    fn c(self: Self) u16 {
        return @intCast(self.col);
    }
    fn manhattan(self: Self, p: Self) CT {
        const res = myf.manhattan(self.toArr(), p.toArr());
        return @intCast(res);
    }
    fn add(self: Self, p: Self) Point {
        return .{
            .row = self.row + p.row,
            .col = self.col + p.col,
        };
    }
    fn delta(self: Self, p: Self) [2]CT {
        return .{
            self.row - p.row,
            self.col - p.col,
        };
    }
};

const HashCtx = struct {
    pub fn hash(_: @This(), key: Point) u32 {
        return @bitCast([2]CT{ key.row, key.col });
    }
    pub fn eql(_: @This(), a: Point, b: Point, _: usize) bool {
        return a.eq(b);
    }
};
const Edges = std.ArrayHashMap(Point, Point, HashCtx, true);

pub fn main() !void {
    const start = time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer if (gpa.deinit() == .leak) expect(false) catch @panic("TEST FAIL");
    // const allocator = gpa.allocator();
    // var buffer: [70_000]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buffer);
    // const allocator = fba.allocator();

    // const filename = try myf.getAppArg(allocator, 1);
    // const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    // const input = try myf.readFile(allocator, target_file);
    // std.debug.print("Input size: {d}\n\n", .{input.len});
    // defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // const input_attributes = try myf.getInputAttributes(input);
    // End setup

    // std.debug.print("{s}\n", .{input});
}

const map = blk: {
    const buttons = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A };
    var btn_coord: [buttons.len]Point = undefined;
    for (buttons) |val| {
        for (0..keypad.len) |i| {
            for (0..keypad[0].len) |j| {
                if (val == keypad[i][j])
                    btn_coord[val] = Point.init(i, j);
            }
        }
    }

    break :blk btn_coord;
};

const N = Point.init(-1, -1);
const Ad = Point.init(0, 0);
const U = Point.init(-1, 0);
const D = Point.init(1, 0);
const L = Point.init(0, -1);
const R = Point.init(0, 1);

const DirPad = enum { LEFT, RIGHT, UP, DOWN, A };
const start_row = 3;
const start_col = 2;

const X = 16;
const A = 10;

const keypad = [_][3]u8{
    .{ 7, 8, 9 },
    .{ 4, 5, 6 },
    .{ 1, 2, 3 },
    .{ X, 0, A },
};

const rows: i8 = keypad.len;
const cols: i8 = keypad[0].len;

const RobotPad = struct {
    pos: Point,
};

fn inBounds(p: Point) bool {
    return 0 <= p.row and p.row < rows and 0 <= p.col and p.col < cols and
        !p.eq(Point.init(3, 0));
}

const Graph = std.AutoArrayHashMap([2]DirPad, DirPad);

const State = struct {
    steps: u8,
    index: u8,
    keypad_pos: Point,

    dp: *DirTreePad,

    const Self = @This();

    fn copy(self: *Self, allocator: Allocator) !Self {
        return State{
            .index = self.index,
            .steps = self.steps,
            .keypad_pos = self.keypad_pos,
            .dp = try self.dp.copy(allocator),
        };
    }

    fn cmp(_: void, a: Self, b: Self) std.math.Order {
        if (a.steps < b.steps) return .lt;
        if (a.steps > b.steps) return .gt;
        return .eq;
    }
};

const DirTreePad = struct {
    const Self = @This();
    value: DirPad,
    child: ?*DirTreePad,

    fn apply(self: *Self, dp: DirPad, graph: Graph) ?*Self {
        if (self.child == null) return self; // Move keyboard or press .A
        if (dp == .A) {
            if (self.value == .A) {
                return self.child.?.*.apply(.A, graph);
            }
            if (graph.get(.{ self.child.?.value, self.value })) |res| {
                self.child.?.*.value = res;
                return self;
            }
        }

        if (graph.get(.{ self.value, dp })) |res| {
            self.value = res;
            return self;
        }
        return null;
    }

    fn init(allocator: Allocator, value: DirPad, depth: usize) !?*DirTreePad {
        if (depth == 0) return null;
        const node = try allocator.create(DirTreePad);
        node.value = value;
        node.child = try Self.init(allocator, value, depth - 1);
        return node;
    }

    fn copy(self: *Self, allocator: Allocator) !*DirTreePad {
        const newNode = try allocator.create(DirTreePad);
        newNode.value = self.value;
        newNode.child = if (self.child) |child| try child.copy(allocator) else null;
        return newNode;
    }

    fn free(self: *Self, allocator: Allocator) void {
        if (self.child) |child| child.free(allocator);
        allocator.destroy(self);
    }
};

// LDA LA A RRU(A) DA A LUA RA | LDLA RRUA DA UA | LDA RUA LDLA RUA RA A  DA UA LDLA RA RUA A A DA LUA RA
fn genDirPadGraph(allocator: Allocator) !Graph {
    var dpgraph = Graph.init(allocator);

    try dpgraph.put(.{ .A, .LEFT }, .UP);
    try dpgraph.put(.{ .A, .DOWN }, .RIGHT);
    try dpgraph.put(.{ .RIGHT, .LEFT }, .DOWN);
    try dpgraph.put(.{ .RIGHT, .UP }, .A);
    try dpgraph.put(.{ .UP, .RIGHT }, .A);
    try dpgraph.put(.{ .UP, .DOWN }, .DOWN);
    try dpgraph.put(.{ .DOWN, .UP }, .UP);
    try dpgraph.put(.{ .DOWN, .LEFT }, .LEFT);
    try dpgraph.put(.{ .DOWN, .RIGHT }, .RIGHT);
    try dpgraph.put(.{ .LEFT, .RIGHT }, .DOWN);
    return dpgraph;
}

fn codeMover(allocator: Allocator, graph: Graph, code: []const u8) !void {
    const start = map[A];

    const dp_values: [5]DirPad = .{ .A, .UP, .DOWN, .LEFT, .RIGHT };

    // var pqueue = PriorityQueue(State, void, State.cmp).init(allocator, undefined);
    var pqueue = try Deque(State).init(allocator);
    defer pqueue.deinit();

    try pqueue.pushBack(.{
        .index = 0,
        .keypad_pos = start,
        .steps = 0,
        .dp = (try DirTreePad.init(allocator, .A, 2)).?,
    });

    while (pqueue.len() != 0) {
        var state = pqueue.popFront().?;
        defer state.dp.free(allocator);
        // printa(state);

        if (state.index == 3) {
            printa(state.steps);
            break;
        }

        for (dp_values) |dp| {
            var new_state = try state.copy(allocator);
            var valid = false;
            if (new_state.dp.apply(dp, graph)) |res| {
                if (res.child == null) {
                    if (res.value == .A) {
                        const i, const j = new_state.keypad_pos.cast();
                        printa(new_state);

                        if (state.dp.value == .A) {
                            if (keypad[i][j] != 10)
                                printa(keypad[i][j]);
                        }
                        if (code[new_state.index] == keypad[i][j]) {
                            new_state.index += 1;
                            valid = true;
                        }
                    } else {
                        if (nextKeypad(new_state.keypad_pos, res.value)) |new_kp| {
                            new_state.keypad_pos = new_kp;
                            valid = true;
                        }
                    }
                } else {
                    valid = true;
                }
            }
            if (valid) {
                if (new_state.index == 1) printa(new_state);
                new_state.steps += 1;
                try pqueue.pushBack(new_state);
                continue;
            }
            new_state.dp.free(allocator);
        }
    }
}

fn nextKeypad(pos: Point, dir: DirPad) ?Point {
    const d = switch (dir) {
        .UP => Point.init(-1, 0),
        .DOWN => Point.init(1, 0),
        .LEFT => Point.init(0, -1),
        .RIGHT => Point.init(0, 1),
        else => unreachable,
    };
    const new_point = pos.add(d);
    if (inBounds(new_point)) return new_point;
    return null;
}

test "example" {
    const allocator = std.testing.allocator;

    const input = @embedFile("in/d21t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    var graph = try genDirPadGraph(allocator);
    defer graph.deinit();

    var in_iter = std.mem.tokenizeSequence(u8, input, input_attributes.delim);
    while (in_iter.next()) |row| {
        var code: [4]u8 = undefined;
        for (row, 0..) |c, k| {
            code[k] = try std.fmt.charToDigit(c, 16);
        }
        try codeMover(allocator, graph, &code);
        break;
    }
}
