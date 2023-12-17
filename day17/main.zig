const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

pub const input = @embedFile("input.txt");
const example1 = @embedFile("example1.txt");
const example2 = @embedFile("example2.txt");
const example3 = @embedFile("example3.txt");

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
    try std.testing.expectEqual(@as(u64, 102), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 94), try solve(.two, example1, std.testing.allocator));
    try std.testing.expectEqual(@as(u64, 71), try solve(.two, example3, std.testing.allocator));
}

const Dir = enum(u2) { l, r, u, d };
fn NodePart(comptime part: Part) type {
    return struct {
        const Self = @This();

        distance: u32,

        x: u8,
        y: u8,
        dir: Dir,
        dist: u8,
        min_dist: if (part == .two) u8 else void,

        // Part 1
        const maximum_dist1 = 3;
        // Part 2
        const minimum_dist = 4;
        const maximum_dist2 = 10;

        pub fn canLeft(n: Self, width: usize, height: usize, buffer: []const u8) ?Self {
            if (part == .two and n.min_dist != 0) return null;
            var new: Self = b: {
                switch (n.dir) {
                    .r => {
                        if (n.y == 0) return null;
                        break :b .{ .distance = undefined, .x = n.x, .y = n.y - 1, .dir = .u, .dist = 1, .min_dist = if (part == .two) minimum_dist - 1 else {} };
                    },
                    .l => {
                        if (n.y == height - 1) return null;
                        break :b .{ .distance = undefined, .x = n.x, .y = n.y + 1, .dir = .d, .dist = 1, .min_dist = if (part == .two) minimum_dist - 1 else {} };
                    },
                    .u => {
                        if (n.x == 0) return null;
                        break :b .{ .distance = undefined, .x = n.x - 1, .y = n.y, .dir = .l, .dist = 1, .min_dist = if (part == .two) minimum_dist - 1 else {} };
                    },
                    .d => {
                        if (n.x == width - 1) return null;
                        break :b .{ .distance = undefined, .x = n.x + 1, .y = n.y, .dir = .r, .dist = 1, .min_dist = if (part == .two) minimum_dist - 1 else {} };
                    },
                }
            };
            new.distance = n.distance + new.getCost(width, buffer);
            return new;
        }
        pub fn canRight(n: Self, width: usize, height: usize, buffer: []const u8) ?Self {
            if (part == .two and n.min_dist != 0) return null;
            var new: Self = b: {
                switch (n.dir) {
                    .l => {
                        if (n.y == 0) return null;
                        break :b .{ .distance = undefined, .x = n.x, .y = n.y - 1, .dir = .u, .dist = 1, .min_dist = if (part == .two) minimum_dist - 1 else {} };
                    },
                    .r => {
                        if (n.y == height - 1) return null;
                        break :b .{ .distance = undefined, .x = n.x, .y = n.y + 1, .dir = .d, .dist = 1, .min_dist = if (part == .two) minimum_dist - 1 else {} };
                    },
                    .d => {
                        if (n.x == 0) return null;
                        break :b .{ .distance = undefined, .x = n.x - 1, .y = n.y, .dir = .l, .dist = 1, .min_dist = if (part == .two) minimum_dist - 1 else {} };
                    },
                    .u => {
                        if (n.x == width - 1) return null;
                        break :b .{ .distance = undefined, .x = n.x + 1, .y = n.y, .dir = .r, .dist = 1, .min_dist = if (part == .two) minimum_dist - 1 else {} };
                    },
                }
            };
            new.distance = n.distance + new.getCost(width, buffer);
            return new;
        }
        pub fn canForw(n: Self, width: usize, height: usize, buffer: []const u8) ?Self {
            if (part == .one and n.dist >= maximum_dist1) return null;
            if (part == .two and n.dist >= maximum_dist2) return null;
            var new: Self = b: {
                switch (n.dir) {
                    .l => {
                        if (n.x == 0) return null;
                        break :b .{ .distance = undefined, .x = n.x - 1, .y = n.y, .dir = .l, .dist = n.dist + 1, .min_dist = if (part == .two) n.min_dist -| 1 else {} };
                    },
                    .r => {
                        if (n.x == width - 1) return null;
                        break :b .{ .distance = undefined, .x = n.x + 1, .y = n.y, .dir = .r, .dist = n.dist + 1, .min_dist = if (part == .two) n.min_dist -| 1 else {} };
                    },
                    .u => {
                        if (n.y == 0) return null;
                        break :b .{ .distance = undefined, .x = n.x, .y = n.y - 1, .dir = .u, .dist = n.dist + 1, .min_dist = if (part == .two) n.min_dist -| 1 else {} };
                    },
                    .d => {
                        if (n.y == height - 1) return null;
                        break :b .{ .distance = undefined, .x = n.x, .y = n.y + 1, .dir = .d, .dist = n.dist + 1, .min_dist = if (part == .two) n.min_dist -| 1 else {} };
                    },
                }
            };
            new.distance = n.distance + new.getCost(width, buffer);
            return new;
        }

        pub fn getCost(n: Self, width: usize, buffer: []const u8) u8 {
            return getAtPos(n.x, n.y, width + 1, buffer) - '0';
        }

        pub fn compare(_: void, a: Self, b: Self) std.math.Order {
            return std.math.order(a.distance, b.distance);
        }
    };
}

fn addNullableSliceToQueue(comptime T: type, comptime len: usize, queue: anytype, slice: [len]?T) !void {
    try queue.ensureUnusedCapacity(slice.len);
    inline for (slice[0..len]) |maybe_e| {
        if (maybe_e) |e| queue.add(e) catch unreachable;
    }
}

fn NodeHashmapCtx(comptime part: Part) type {
    return struct {
        pub fn hash(_: @This(), key: NodePart(part)) u64 {
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHash(&hasher, key.x);
            std.hash.autoHash(&hasher, key.y);
            std.hash.autoHash(&hasher, key.dir);
            std.hash.autoHash(&hasher, key.dist);
            if (part == .two)
                std.hash.autoHash(&hasher, key.min_dist);
            return @truncate(hasher.final());
        }
        pub fn eql(_: @This(), a: NodePart(part), b: NodePart(part)) bool {
            return a.x == b.x and a.y == b.y and a.dir == b.dir and a.dist == b.dist and a.min_dist == b.min_dist;
        }
    };
}

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    const Node = NodePart(part);

    const width = indexOf(u8, in, '\n').?;
    const height = in.len / (width + 1);

    const start: Node = .{ .distance = 0, .x = 0, .y = 0, .dir = .r, .dist = 0, .min_dist = if (part == .two) Node.minimum_dist else {} };

    var memo = std.HashMap(Node, usize, NodeHashmapCtx(part), std.hash_map.default_max_load_percentage).init(allocator);
    defer memo.deinit();

    var queue = std.PriorityQueue(Node, void, Node.compare).init(allocator, {});
    defer queue.deinit();

    try addNullableSliceToQueue(Node, 3, &queue, [_]?Node{
        start.canLeft(width, height, in),
        start.canRight(width, height, in),
        start.canForw(width, height, in),
    });

    while (queue.removeOrNull()) |curr| {
        if (memo.get(curr)) |memo_val| if (curr.distance >= memo_val) continue;
        try memo.put(curr, curr.distance);

        if (part == .one and curr.x == width - 1 and curr.y == height - 1) {
            return curr.distance;
        }
        if (part == .two and curr.x == width - 1 and curr.y == height - 1 and curr.min_dist == 0) {
            return curr.distance;
        }

        const neighbours = [_]?Node{
            curr.canLeft(width, height, in),
            curr.canRight(width, height, in),
            curr.canForw(width, height, in),
        };
        try addNullableSliceToQueue(Node, neighbours.len, &queue, neighbours);
    }

    unreachable;
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

fn getAtPos(x: usize, y: usize, width: usize, buf: []const u8) u8 {
    return buf[y * width + x];
}

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
