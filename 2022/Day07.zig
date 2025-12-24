const std = @import("std");
const utils = @import("utils.zig");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    const alloc = da.allocator();
    defer _ = da.deinit();

    const data = try utils.read(alloc, "in/d07.txt");
    defer alloc.free(data);

    const result = try solve(alloc, data);
    std.debug.print("Part 1: {d}\n", .{result.p1});
    std.debug.print("Part 2: {d}\n", .{result.p2});
}

const File = struct { name: []const u8, size: usize };
const Directory = struct {
    const Self = @This();
    name: []const u8,
    parent: ?*Self = null,
    subdirs: std.ArrayList(*Self),
    files: std.ArrayList(File),

    fn init(allocator: Allocator, name: []const u8, parent: ?*Self) !*Self {
        const new = try allocator.create(Self);
        new.name = name;
        new.parent = parent;
        new.files = .empty;
        new.subdirs = .empty;
        return new;
    }

    fn size(self: Self) usize {
        var total: usize = 0;
        for (self.subdirs.items) |dir| total += dir.size();
        for (self.files.items) |file| total += file.size;
        return total;
    }

    fn deinit(self: *Self, alloc: Allocator) void {
        for (self.subdirs.items) |dir| dir.deinit(alloc);
        self.files.deinit(alloc);
        self.subdirs.deinit(alloc);
        alloc.destroy(self);
    }
};

fn solve(alloc: Allocator, data: []const u8) !struct { p1: usize, p2: usize } {
    var splitIter = std.mem.splitScalar(u8, data, '\n');

    var root_dir: ?*Directory = null;
    defer root_dir.?.deinit(alloc);

    var dir: ?*Directory = null;
    var row: std.ArrayList([]const u8) = .{};
    defer row.deinit(alloc);
    while (splitIter.next()) |item| {
        row.clearRetainingCapacity();
        var rowIter = std.mem.splitScalar(u8, item, ' ');
        while (rowIter.next()) |elem| try row.append(alloc, elem);

        if (row.items[0][0] == '$') {
            const cmd = row.items[1];
            if (std.mem.eql(u8, cmd, "cd")) {
                if (row.items[2][0] == '/') {
                    if (dir == null) {
                        dir = try Directory.init(alloc, row.items[2], null);
                        root_dir = dir;
                    }
                } else if (row.items[2][0] == '.' and row.items[2][1] == '.') {
                    dir = dir.?.parent;
                } else {
                    for (dir.?.subdirs.items) |subdir| {
                        if (std.mem.eql(u8, subdir.name, row.items[2])) {
                            dir = subdir;
                            break;
                        }
                    } else {
                        const new_dir = try Directory.init(alloc, row.items[2], dir.?);
                        try dir.?.subdirs.append(alloc, new_dir);
                        dir = new_dir;
                    }
                }
            }
        } else if (std.mem.eql(u8, row.items[0], "dir")) {
            for (dir.?.subdirs.items) |subdir| {
                if (std.mem.eql(u8, subdir.name, row.items[1])) break;
            } else {
                try dir.?.subdirs.append(alloc, try Directory.init(alloc, row.items[1], dir.?));
            }
        } else {
            for (dir.?.files.items) |file| {
                if (std.mem.eql(u8, file.name, row.items[1])) break;
            } else {
                const new_file: File = .{ .name = row.items[1], .size = try std.fmt.parseUnsigned(usize, row.items[0], 10) };
                try dir.?.files.append(alloc, new_file);
            }
        }
    }

    var map = std.StringHashMap(usize).init(alloc);
    try directorySize(alloc, root_dir.?, try alloc.dupe(u8, root_dir.?.name), &map);
    defer {
        var it = map.keyIterator();
        while (it.next()) |k| alloc.free(k.*);
        map.deinit();
    }

    const total_used = root_dir.?.size();
    var total1: usize = 0;
    var total2: usize = total_used;
    var it = map.valueIterator();
    while (it.next()) |value| {
        if (value.* <= 100000) total1 += value.*;
        if (value.* >= 30_000_000 - (70_000_000 - total_used) and value.* < total2) total2 = value.*;
    }
    return .{ .p1 = total1, .p2 = total2 };
}

fn directorySize(alloc: Allocator, dir: *Directory, name: []const u8, map: *std.StringHashMap(usize)) !void {
    try map.put(name, dir.size());
    for (dir.subdirs.items) |next_dir|
        try directorySize(alloc, next_dir, try std.mem.join(alloc, "/", &[_][]const u8{ name, next_dir.name }), map);
}
