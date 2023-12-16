const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

pub const input = @embedFile("input.txt");
const example1 = @embedFile("example1.txt");
const example2 = @embedFile("example2.txt");

const Array2D = @import("array2d.zig").Array2D;
const Part = enum { one, two };

pub const std_options = struct {
    pub const log_level = .info;
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u64, 46), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 51), try solve(.two, example1, std.testing.allocator));
}

const Dir = enum(u2) { l, u, r, d };
const State = packed struct(u16) {
    x: u7,
    y: u7,
    dir: Dir,

    pub fn moveInDir(state: State, dir: Dir) State {
        return switch (dir) {
            .l => .{ .x = state.x - 1, .y = state.y, .dir = dir },
            .r => .{ .x = state.x + 1, .y = state.y, .dir = dir },
            .u => .{ .x = state.x, .y = state.y - 1, .dir = dir },
            .d => .{ .x = state.x, .y = state.y + 1, .dir = dir },
        };
    }
};
const StateSet = AutoHashSet(State);
// const StateSet = HashSet(State, IntegerHashmapCtx(State), std.hash_map.default_max_load_percentage);

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    const width = indexOf(u8, in, '\n').? + 1;
    const height = in.len / width;

    var energized = try Array2D(bool).initWithDefault(allocator, width, height, false);
    defer energized.deinit(allocator);
    var visited = StateSet.init(allocator);
    defer visited.deinit();

    if (part == .one) {
        try subsolve(.{ .x = 0, .y = 0, .dir = .r }, &visited, &energized, in, @intCast(width), @intCast(height));

        // std.debug.print("\n{c}", .{energized});

        return std.mem.count(bool, energized.data, &.{true});
    }

    var best_count: usize = 0;

    for (0..width) |x| {
        try subsolve(.{ .x = @intCast(x), .y = 0, .dir = .d }, &visited, &energized, in, @intCast(width), @intCast(height));
        best_count = @max(best_count, std.mem.count(bool, energized.data, &.{true}));
        @memset(energized.data, false);
        visited.clearRetainingCapacity();

        try subsolve(.{ .x = @intCast(x), .y = @intCast(height - 1), .dir = .u }, &visited, &energized, in, @intCast(width), @intCast(height));
        best_count = @max(best_count, std.mem.count(bool, energized.data, &.{true}));
        @memset(energized.data, false);
        visited.clearRetainingCapacity();
    }
    for (0..height) |y| {
        try subsolve(.{ .x = 0, .y = @intCast(y), .dir = .r }, &visited, &energized, in, @intCast(width), @intCast(height));
        best_count = @max(best_count, std.mem.count(bool, energized.data, &.{true}));
        @memset(energized.data, false);
        visited.clearRetainingCapacity();

        try subsolve(.{ .x = @intCast(width - 1), .y = @intCast(y), .dir = .l }, &visited, &energized, in, @intCast(width), @intCast(height));
        best_count = @max(best_count, std.mem.count(bool, energized.data, &.{true}));
        @memset(energized.data, false);
        visited.clearRetainingCapacity();
    }

    return best_count;
}

fn subsolve(state: State, visited: *StateSet, energized: *Array2D(bool), map: []const u8, width: u8, height: u8) !void {
    if (visited.contains(state)) return;
    try visited.put(state, {});

    const tile = getAtPos(state.x, state.y, width, map);
    if (tile == '\n') return;
    energized.set(state.x, state.y, true);

    switch (tile) {
        '.' => {
            if (state.dir == .l and state.x == 0 or state.dir == .r and state.x == width - 1 or
                state.dir == .u and state.y == 0 or state.dir == .d and state.y == height - 1)
            {
                return;
            }
            try subsolve(state.moveInDir(state.dir), visited, energized, map, width, height);
        },
        '/' => {
            const new_dir: Dir = switch (state.dir) {
                .r => .u,
                .u => .r,
                .l => .d,
                .d => .l,
            };
            if (new_dir == .l and state.x == 0 or new_dir == .r and state.x == width - 1 or
                new_dir == .u and state.y == 0 or new_dir == .d and state.y == height - 1)
            {
                return;
            }

            try subsolve(state.moveInDir(new_dir), visited, energized, map, width, height);
        },
        '\\' => {
            const new_dir: Dir = switch (state.dir) {
                .r => .d,
                .d => .r,
                .l => .u,
                .u => .l,
            };
            if (new_dir == .l and state.x == 0 or new_dir == .r and state.x == width - 1 or
                new_dir == .u and state.y == 0 or new_dir == .d and state.y == height - 1)
            {
                return;
            }

            try subsolve(state.moveInDir(new_dir), visited, energized, map, width, height);
        },
        '-' => {
            if (state.dir == .l or state.dir == .r) {
                if (state.dir == .l and state.x == 0 or state.dir == .r and state.x == width - 1) {
                    return;
                }
                try subsolve(state.moveInDir(state.dir), visited, energized, map, width, height);
                return;
            }

            if (state.x != 0) try subsolve(state.moveInDir(.l), visited, energized, map, width, height);
            if (state.x != width - 1) try subsolve(state.moveInDir(.r), visited, energized, map, width, height);
        },
        '|' => {
            if (state.dir == .u or state.dir == .d) {
                if (state.dir == .u and state.y == 0 or state.dir == .d and state.y == height - 1) {
                    return;
                }
                try subsolve(state.moveInDir(state.dir), visited, energized, map, width, height);
                return;
            }

            if (state.y != 0) try subsolve(state.moveInDir(.u), visited, energized, map, width, height);
            if (state.y != height - 1) try subsolve(state.moveInDir(.d), visited, energized, map, width, height);
        },
        else => {
            unreachable;
        },
    }

    // _ = energized;
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

fn AutoHashSet(comptime T: type) type {
    return std.AutoHashMap(T, void);
}
fn HashSet(comptime T: type, comptime Context: anytype, comptime max_load_percentage: u64) type {
    return std.HashMap(T, void, Context, max_load_percentage);
}

fn getAtPos(x: usize, y: usize, width: usize, buf: []const u8) u8 {
    return buf[y * width + x];
}
fn setAtPos(comptime T: type, x: usize, y: usize, width: usize, buf: [*]T, value: T) void {
    buf[y * width + x] = value;
}

fn SliceArrayHashmapCtx(comptime T: type) type {
    if (T == u8)
        @compileError("Use a StringHashMap instead when using a []const u8 key");
    return struct {
        pub fn hash(_: @This(), key: []const T) u32 {
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHashStrat(&hasher, key, .Deep);
            return @truncate(hasher.final());
        }
        pub fn eql(_: @This(), a: []const T, b: []const T, _: usize) bool {
            return std.mem.eql(T, a, b);
        }
    };
}
// TODO: Improve this lol
// fn IntegerHashmapCtx(comptime T: type) type {
//     switch (@typeInfo(T)) {
//         .Struct => |info| {
//             if (info.backing_integer == null) @compileError("Struct must be backed by an integer");
//             return struct {
//                 pub fn hash(_: @This(), key: T) u64 {
//                     return @as(info.backing_integer.?, @bitCast(key));
//                 }
//                 pub fn eql(_: @This(), a: T, b: T) bool {
//                     return @as(info.backing_integer.?, @bitCast(a)) == @as(info.backing_integer.?, @bitCast(b));
//                 }
//             };
//         },
//         .Enum => {
//             return struct {
//                 pub fn hash(_: @This(), key: T) u64 {
//                     return @intFromEnum(key);
//                 }
//                 pub fn eql(_: @This(), a: T, b: T) bool {
//                     return a == b;
//                 }
//             };
//         },
//         .Int => {
//             return struct {
//                 pub fn hash(_: @This(), key: T) u64 {
//                     return key;
//                 }
//                 pub fn eql(_: @This(), a: T, b: T) bool {
//                     return a == b;
//                 }
//             };
//         },
//         else => @compileError("Key must be an integer type or a type backed by an integer"),
//     }
// }

fn lcm(a: u64, b: u64) u64 {
    return a * b / std.math.gcd(a, b);
}
fn lcmSlice(numbers: []const u64) u64 {
    return if (numbers.len > 2)
        lcm(numbers[0], lcmSlice(numbers[1..]))
    else
        lcm(numbers[0], numbers[1]);
}

fn splitOnce(comptime T: type, haystack: []const T, needle: []const T) struct { []const T, []const T } {
    const idx = std.mem.indexOf(T, haystack, needle) orelse return .{ haystack, &.{} };
    return .{ haystack[0..idx], haystack[(idx + needle.len)..] };
}
fn splitOnceScalar(comptime T: type, buffer: []const T, delimiter: T) struct { []const T, []const T } {
    const idx = std.mem.indexOfScalar(T, buffer, delimiter) orelse return .{ buffer, &.{} };
    return .{ buffer[0..idx], buffer[(idx + 1)..] };
}
