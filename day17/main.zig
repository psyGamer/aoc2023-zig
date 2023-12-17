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

fn Node(comptime part: Part) type {
    return packed struct(u24) {
        const Self = @This();

        x: u8,
        y: u8,
        dir: Dir,
        dist: u6,

        const minimum_dist = if (part == .one) 0 else 4;
        const maximum_dist = if (part == .one) 3 else 10;

        pub fn canLeft(n: Self, width: usize, height: usize) ?Self {
            if (n.dist < minimum_dist) return null;
            switch (n.dir) {
                .r => {
                    if (n.y == 0) return null;
                    return .{ .x = n.x, .y = n.y - 1, .dir = .u, .dist = 1 };
                },
                .l => {
                    if (n.y == height - 1) return null;
                    return .{ .x = n.x, .y = n.y + 1, .dir = .d, .dist = 1 };
                },
                .u => {
                    if (n.x == 0) return null;
                    return .{ .x = n.x - 1, .y = n.y, .dir = .l, .dist = 1 };
                },
                .d => {
                    if (n.x == width - 1) return null;
                    return .{ .x = n.x + 1, .y = n.y, .dir = .r, .dist = 1 };
                },
            }
        }

        pub fn canRight(n: Self, width: usize, height: usize) ?Self {
            if (n.dist < minimum_dist) return null;
            switch (n.dir) {
                .l => {
                    if (n.y == 0) return null;
                    return .{ .x = n.x, .y = n.y - 1, .dir = .u, .dist = 1 };
                },
                .r => {
                    if (n.y == height - 1) return null;
                    return .{ .x = n.x, .y = n.y + 1, .dir = .d, .dist = 1 };
                },
                .d => {
                    if (n.x == 0) return null;
                    return .{ .x = n.x - 1, .y = n.y, .dir = .l, .dist = 1 };
                },
                .u => {
                    if (n.x == width - 1) return null;
                    return .{ .x = n.x + 1, .y = n.y, .dir = .r, .dist = 1 };
                },
            }
        }

        pub fn canForw(n: Self, width: usize, height: usize) ?Self {
            if (n.dist >= maximum_dist) return null;
            switch (n.dir) {
                .l => {
                    if (n.x == 0) return null;
                    return .{ .x = n.x - 1, .y = n.y, .dir = .l, .dist = n.dist + 1 };
                },
                .r => {
                    if (n.x == width - 1) return null;
                    return .{ .x = n.x + 1, .y = n.y, .dir = .r, .dist = n.dist + 1 };
                },
                .u => {
                    if (n.y == 0) return null;
                    return .{ .x = n.x, .y = n.y - 1, .dir = .u, .dist = n.dist + 1 };
                },
                .d => {
                    if (n.y == height - 1) return null;
                    return .{ .x = n.x, .y = n.y + 1, .dir = .d, .dist = n.dist + 1 };
                },
            }
        }

        pub fn getCost(n: Self, width: usize, buffer: []const u8) u8 {
            return getAtPos(n.x, n.y, width + 1, buffer) - '0';
        }
    };
}

fn DistanceNode(comptime part: Part) type {
    return struct {
        const Self = @This();

        dist: u32,
        node: Node(part),

        pub fn canLeft(n: Self, width: usize, height: usize, buffer: []const u8) ?Self {
            var new = n.node.canLeft(width, height) orelse return null;
            return .{ .dist = n.dist + new.getCost(width, buffer), .node = new };
        }
        pub fn canRight(n: Self, width: usize, height: usize, buffer: []const u8) ?Self {
            var new = n.node.canRight(width, height) orelse return null;
            return .{ .dist = n.dist + new.getCost(width, buffer), .node = new };
        }
        pub fn canForw(n: Self, width: usize, height: usize, buffer: []const u8) ?Self {
            var new = n.node.canForw(width, height) orelse return null;
            return .{ .dist = n.dist + new.getCost(width, buffer), .node = new };
        }

        pub fn compare(_: void, a: Self, b: Self) std.math.Order {
            return std.math.order(a.dist, b.dist);
        }
    };
}

fn addNullableSliceToQueue(comptime T: type, comptime len: usize, queue: anytype, slice: [len]?T) !void {
    try queue.ensureUnusedCapacity(slice.len);
    inline for (slice[0..len]) |maybe_e| {
        if (maybe_e) |e| queue.add(e) catch unreachable;
    }
}

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    const width = indexOf(u8, in, '\n').?;
    const height = in.len / (width + 1);

    const start: DistanceNode(part) = .{ .dist = 0, .node = .{ .x = 0, .y = 0, .dir = .r, .dist = 0 } };

    var visited = try allocator.alloc(bool, std.math.maxInt(u24));
    defer allocator.free(visited);
    @memset(visited, false);

    var queue = std.PriorityQueue(DistanceNode(part), void, DistanceNode(part).compare).init(allocator, {});
    defer queue.deinit();

    try addNullableSliceToQueue(DistanceNode(part), 3, &queue, [_]?DistanceNode(part){
        start.canLeft(width, height, in),
        start.canRight(width, height, in),
        start.canForw(width, height, in),
    });

    while (queue.removeOrNull()) |curr| {
        // if (memo.get(curr)) |memo_val| if (curr.distance >= memo_val) continue;
        // try memo.put(curr, curr.distance);
        if (visited[@as(u24, @bitCast(curr.node))]) continue;
        visited[@as(u24, @bitCast(curr.node))] = true;

        if (curr.node.x == width - 1 and curr.node.y == height - 1 and curr.node.dist >= Node(part).minimum_dist) {
            return curr.dist;
        }

        const neighbours = [_]?DistanceNode(part){
            curr.canLeft(width, height, in),
            curr.canRight(width, height, in),
            curr.canForw(width, height, in),
        };
        try addNullableSliceToQueue(DistanceNode(part), neighbours.len, &queue, neighbours);
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
