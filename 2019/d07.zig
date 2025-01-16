const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Allocator = std.mem.Allocator;

const State = struct {
    registers: []i32,
    phase: i32,
    phase_set: bool = false,
    pc: u16 = 0,
    output: i32 = 0,
};

fn get_value(value: anytype, comptime param_num: usize, op: []const i32, i: usize) @TypeOf(value) {
    const position = @mod(@divFloor(value, if (param_num == 1) 100 else 1000), 10) == 0;
    const item = op[i + param_num];
    return if (position) op[@intCast(item)] else item;
}

fn machine(state: *State, input_value: @TypeOf(state.registers[0])) bool {
    var op = state.registers;
    while (true) {
        var i = state.pc;
        defer state.pc = i;

        const value = op[i];
        switch (@mod(value, 100)) {
            1 => {
                op[@intCast(op[i + 3])] = get_value(value, 1, op, i) + get_value(value, 2, op, i);
                i += 4;
            },
            2 => {
                op[@intCast(op[i + 3])] = get_value(value, 1, op, i) * get_value(value, 2, op, i);
                i += 4;
            },
            3 => {
                if (!state.phase_set) {
                    op[@intCast(op[i + 1])] = state.phase;
                    state.phase_set = true;
                } else {
                    op[@intCast(op[i + 1])] = input_value;
                }
                i += 2;
            },
            4 => {
                state.output = op[@intCast(op[i + 1])];
                i += 2;
                return false;
            },
            5 => i = if (get_value(value, 1, op, i) != 0) @intCast(get_value(value, 2, op, i)) else i + 3,
            6 => i = if (get_value(value, 1, op, i) == 0) @intCast(get_value(value, 2, op, i)) else i + 3,
            7 => {
                op[@intCast(op[i + 3])] = if (get_value(value, 1, op, i) < get_value(value, 2, op, i)) 1 else 0;
                i += 4;
            },
            8 => {
                op[@intCast(op[i + 3])] = if (get_value(value, 1, op, i) == get_value(value, 2, op, i)) 1 else 0;
                i += 4;
            },
            99 => return true,
            else => unreachable,
        }
    }
}

fn solver(allocator: Allocator, ops: []const i32, start_state: []const i32, part1: bool) !usize {
    var permutation_state: [5]i32 = undefined;
    @memcpy(&permutation_state, start_state);

    var max_signal: i32 = 0;
    var perm_iter = permutate(i32, &permutation_state);
    while (perm_iter.next()) |phase_sequence| {
        var input_signal: i32 = 0;
        if (part1) {
            for (phase_sequence) |phase| {
                var state: State = .{ .registers = try allocator.dupe(@TypeOf(ops[0]), ops), .phase = phase };
                defer allocator.free(state.registers);

                while (!machine(&state, input_signal)) {}
                input_signal = state.output;
            }
        } else {
            var curr_state: u8 = 0;
            var states: [5]State = undefined;
            for (&states, phase_sequence) |*s, phase| s.* = State{
                .registers = try allocator.dupe(@TypeOf(ops[0]), ops),
                .phase = phase,
            };
            defer for (&states) |*s| allocator.free(s.*.registers);

            while (!machine(&states[curr_state], input_signal)) {
                input_signal = states[curr_state].output;
                curr_state += 1;
                if (curr_state >= states.len) curr_state = 0;
            }
        }
        if (input_signal > max_signal) max_signal = input_signal;
    }
    return @intCast(max_signal);
}

pub fn main() !void {
    const start = std.time.nanoTimestamp();
    const writer = std.io.getStdOut().writer();
    defer {
        const end = std.time.nanoTimestamp();
        const elapsed = @as(f128, @floatFromInt(end - start)) / @as(f128, 1_000_000);
        writer.print("\nTime taken: {d:.7}ms\n", .{elapsed}) catch {};
    }
    var buffer: [1_100_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const filename = try myf.getAppArg(allocator, 1);
    const target_file = try std.mem.concat(allocator, u8, &.{ "in/", filename });
    const input = try myf.readFile(allocator, target_file);
    defer inline for (.{ filename, target_file, input }) |res| allocator.free(res);
    // End setup

    var op_list = std.ArrayList(i32).init(allocator);
    defer op_list.deinit();

    var in_iter = std.mem.tokenizeScalar(u8, std.mem.trimRight(u8, input, "\r\n"), ',');
    while (in_iter.next()) |raw_value| try op_list.append(try std.fmt.parseInt(i32, raw_value, 10));

    try writer.print("Part 1: {d}\nPart 2: {d}\n", .{
        try solver(allocator, op_list.items, &[_]i32{ 0, 1, 2, 3, 4 }, true),
        try solver(allocator, op_list.items, &[_]i32{ 5, 6, 7, 8, 9 }, false),
    });
}

// https://github.com/svc-user/zig-permutate/blob/master/src/permutate.zig
pub fn permutate(comptime T: type, list: []T) PermutationIterator(T) {
    return PermutationIterator(T){
        .list = list[0..],
        .size = @intCast(list.len),
        .state = [_]u4{0} ** 16,
        .stateIndex = 0,
        .first = true,
    };
}

pub fn PermutationIterator(comptime T: type) type {
    return struct {
        list: []T,
        size: u4,
        state: [16]u4,
        stateIndex: u4,
        first: bool,

        const Self = @This();

        inline fn swap(a: *T, b: *T) void {
            const tmp = a.*;
            a.* = b.*;
            b.* = tmp;
        }

        pub fn next(self: *Self) ?[]T {
            if (self.first) {
                self.first = false;
                return self.list;
            }

            while (self.stateIndex < self.size) {
                if (self.state[self.stateIndex] < self.stateIndex) {
                    if (self.stateIndex % 2 == 0) {
                        swap(&self.list[0], &self.list[self.stateIndex]);
                    } else {
                        swap(&self.list[self.state[self.stateIndex]], &self.list[self.stateIndex]);
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
