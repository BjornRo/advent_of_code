const std = @import("std");
const myf = @import("mylib/myfunc.zig");
const Deque = @import("mylib/deque.zig").Deque;
const print = std.debug.print;
const printa = myf.printAny;
const prints = myf.printStr;
const expect = std.testing.expect;
const eqStr = std.mem.eql;

const time = std.time;
const Allocator = std.mem.Allocator;

const Patterns = std.StringArrayHashMap(void);

pub fn main() !void {}

test "example" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i8).init(allocator);
    defer list.deinit();

    const input = @embedFile("in/d19t.txt");
    const input_attributes = try myf.getInputAttributes(input);

    const double_delim = try std.mem.concat(allocator, u8, &.{ input_attributes.delim, input_attributes.delim });
    defer allocator.free(double_delim);

    var in_iter = std.mem.tokenizeSequence(u8, input, double_delim);

    const raw_towel_patterns = in_iter.next().?;
    const raw_desire = in_iter.next().?;

    var patterns = Patterns.init(allocator);
    defer patterns.deinit();

    var patterns_iter = std.mem.tokenizeSequence(u8, raw_towel_patterns, ", ");
    while (patterns_iter.next()) |pattern| try patterns.put(pattern, {});

    var sum2: u64 = 0;

    var desire_iter = std.mem.tokenizeSequence(u8, raw_desire, input_attributes.delim);
    while (desire_iter.next()) |desire| {
        sum2 += try nfa(allocator, desire, patterns);
        // break;
    }
    printa(sum2);
}

const StateMap = std.AutoArrayHashMap(State, u64);

const State = struct {
    index: u8,
    offset: u8, // offset

    const Self = @This();
    fn arr(self: Self) [2]u8 {
        return .{ self.index, self.offset };
    }
};

fn nfa(allocator: Allocator, desire: []const u8, patterns: Patterns) !u64 {
    var curr_state = StateMap.init(allocator);
    var next_state = StateMap.init(allocator);
    defer curr_state.deinit();
    defer next_state.deinit();

    const len = desire.len;
    // const max_ss = 8;

    var sum: u64 = 0;

    _ = patterns.get(desire);

    try curr_state.put(.{ .index = 0, .offset = 1 }, 0);
    while (curr_state.count() != 0) {
        var states_iter = curr_state.iterator();
        // prints("new loop");
        // for (curr_state.keys(), curr_state.values()) |k, v| {
        //     std.debug.print("{any}, {any}\n", .{ k, v });
        // }
        while (states_iter.next()) |item| {
            var key = item.key_ptr.*;
            const value = item.value_ptr.*;
            const index, const offset = key.arr();

            if (index + offset >= len) {
                if (patterns.contains(desire[index .. index + offset - 1]))
                    sum += item.value_ptr.*;
                continue;
            }
            const slice = desire[index .. index + offset];
            if (patterns.contains(slice)) {
                const new_key: State = .{ .index = index + offset, .offset = 1 };
                // printa(new_key);
                if (next_state.get(new_key)) |result| {
                    try next_state.put(new_key, result + value + 1);
                } else {
                    try next_state.put(new_key, 1);
                }
                // const result = next_state.get(key) orelse 1;
                // try next_state.put(key, result + item.value_ptr.*);
            }
            if (key.offset == 8) continue;

            key.offset += 1;

            if (next_state.get(key)) |result| {
                try next_state.put(key, result + value);
            } else {
                try next_state.put(key, value);
            }
            // const result = next_state.get(item.key_ptr.*) orelse 1;
            // try next_state.put(item.key_ptr.*, result + item.value_ptr.*);

            //
        }
        curr_state.clearRetainingCapacity();
        var nstates_iter = next_state.iterator();
        while (nstates_iter.next()) |item| {
            try curr_state.put(item.key_ptr.*, item.value_ptr.*);
        }
        next_state.clearRetainingCapacity();
    }

    //
    printa(sum);
    return sum;
}
