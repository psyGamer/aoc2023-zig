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
    // std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u64, 16), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    // try std.testing.expectEqual(@as(u64, 6), try solve(.two, example2, std.testing.allocator));
}

const Step = struct { x: u16, y: u16, distance: u8 };

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    const width = indexOf(u8, in, '\n').?;
    const height = in.len / (width + 1);

    var map = try Array2D(u8).initWithDefault(allocator, width, height, std.math.maxInt(u8));
    defer map.deinit(allocator);

    var start: Step = undefined;
    var rocks: u16 = 0;

    _ = part;

    var y: usize = 0;
    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| : (y += 1) {
        for (line, 0..) |char, x| {
            switch (char) {
                '.' => continue,
                'S' => start = .{ .x = @intCast(x), .y = @intCast(y), .distance = 1 },
                '#' => {
                    map.set(x, y, 0);
                    rocks += 1;
                },
                else => unreachable,
            }
        }
    }

    var queue = std.ArrayList(Step).init(allocator);
    defer queue.deinit();

    try queue.append(start);

    var end_spots = std.AutoArrayHashMap(Step, void).init(allocator);
    defer end_spots.deinit();

    std.log.warn("Star {}", .{start});

    const max_distance = 64;
    while (queue.popOrNull()) |tile| {
        const curr_tile = map.get(tile.x, tile.y);
        if (curr_tile <= tile.distance) continue;
        map.set(tile.x, tile.y, tile.distance);
        if (tile.distance == max_distance + 1) {
            continue;
        }
        if (tile.x != 0) try queue.append(.{ .x = @intCast(tile.x - 1), .y = @intCast(tile.y), .distance = tile.distance + 1 });
        if (tile.y != 0) try queue.append(.{ .x = @intCast(tile.x), .y = @intCast(tile.y - 1), .distance = tile.distance + 1 });
        if (tile.x != width - 1) try queue.append(.{ .x = @intCast(tile.x + 1), .y = @intCast(tile.y), .distance = tile.distance + 1 });
        if (tile.y != height - 1) try queue.append(.{ .x = @intCast(tile.x), .y = @intCast(tile.y + 1), .distance = tile.distance + 1 });
    }

    // std.debug.print("\n", .{});
    // for (0..map.height) |ny| {
    //     for (0..map.width) |nx| {
    //         if (map.get(nx, ny) == 255) {
    //             std.debug.print("    ", .{});
    //         } else if (map.get(nx, ny) == 0) {
    //             std.debug.print("### ", .{});
    //         } else {
    //             std.debug.print("{d:0>3} ", .{map.get(nx, ny)});
    //         }
    //     }
    //     std.debug.print("\n", .{});
    // }

    var result: u32 = 0;
    for (map.data) |tile| {
        if (tile == 0 or tile == std.math.maxInt(u8)) continue;
        if ((tile + 1) % 2 == max_distance % 2) result += 1;
    }
    return result;
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

fn SliceHashmapCtx(comptime T: type) type {
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
