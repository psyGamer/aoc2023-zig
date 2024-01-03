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
    try std.testing.expectEqual(@as(u64, 94), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 154), try solve(.two, example1, std.testing.allocator));
}

const Dir = enum(u2) { l, r, u, d };
const Vec2u = struct { x: u16, y: u16 };

const NodeState = struct { x: u16, y: u16, dir: Dir };
const NodeDistance = struct { x: u16, y: u16, dir: Dir, dist: u16 };
const Leaf = struct { a: ?NodeDistance, b: ?NodeDistance, c: ?NodeDistance };

fn buildGraph(comptime part: Part, curr_state: NodeState, graph: *std.AutoHashMap(NodeState, Leaf), in: []const u8, width: usize, end_point: Vec2u) !?NodeDistance {
    var curr = curr_state;
    var dist: u16 = 0;

    while (true) {
        dist += 1;

        if (curr.x == end_point.x and curr.y == end_point.y) {
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        }
        if (curr.x == 1 and curr.y == 0 and curr.dir == .u) {
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        }

        const left = curr.dir != .r and getAtPos(curr.x - 1, curr.y, width, in) != '#';
        const right = curr.dir != .l and getAtPos(curr.x + 1, curr.y, width, in) != '#';
        const up = curr.dir != .d and getAtPos(curr.x, curr.y - 1, width, in) != '#';
        const down = curr.dir != .u and getAtPos(curr.x, curr.y + 1, width, in) != '#';

        if (left and right and down) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(part, .{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                    .b = try buildGraph(part, .{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                    .c = try buildGraph(part, .{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (left and right and up) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(part, .{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                    .b = try buildGraph(part, .{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                    .c = try buildGraph(part, .{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (up and down and left) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(part, .{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                    .b = try buildGraph(part, .{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                    .c = try buildGraph(part, .{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (up and down and right) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(part, .{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                    .b = try buildGraph(part, .{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                    .c = try buildGraph(part, .{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        }

        if (right and left) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(part, .{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                    .b = try buildGraph(part, .{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (up and down) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(part, .{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                    .b = try buildGraph(part, .{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (up and right) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(part, .{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                    .b = try buildGraph(part, .{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (up and left) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(part, .{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                    .b = try buildGraph(part, .{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (down and right) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(part, .{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                    .b = try buildGraph(part, .{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (down and left) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(part, .{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                    .b = try buildGraph(part, .{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        }

        if (left) {
            curr.dir = .l;
            curr.x -= 1;
        } else if (right) {
            curr.dir = .r;
            curr.x += 1;
        } else if (up) {
            curr.dir = .u;
            curr.y -= 1;
        } else if (down) {
            curr.dir = .d;
            curr.y += 1;
        } else {
            unreachable;
        }

        if (part == .one) {
            // Assumes a slope is not followed by a slope
            // Kill this branch if it the slope would cause a 180° turn
            switch (getAtPos(curr.x, curr.y, width, in)) {
                '>' => {
                    if (curr.dir == .l) return null;
                    curr.x += 1;
                    curr.dir = .r;
                    dist += 1;
                },
                '<' => {
                    if (curr.dir == .r) return null;
                    curr.x -= 1;
                    curr.dir = .r;
                    dist += 1;
                },
                'v' => {
                    if (curr.dir == .u) return null;
                    curr.y += 1;
                    curr.dir = .d;
                    dist += 1;
                },
                '^' => {
                    if (curr.dir == .d) return null;
                    curr.y -= 1;
                    curr.dir = .u;
                    dist += 1;
                },
                else => continue,
            }
        }
    }
}

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    const width = indexOf(u8, in, '\n').?;
    const height = in.len / (width + 1);

    const start: NodeState = .{ .x = 1, .y = 0, .dir = .d };
    const end: Vec2u = .{ .x = @intCast(width - 2), .y = @intCast(height - 1) };

    var graph = std.AutoHashMap(NodeState, Leaf).init(allocator);
    defer graph.deinit();

    const start_path = try buildGraph(part, .{ .x = start.x, .y = start.y, .dir = .d }, &graph, in, width + 1, end);
    try graph.put(start, .{ .a = start_path, .b = null, .c = null });

    const max_positions = 64;

    var positions = std.AutoArrayHashMap(Vec2u, void).init(allocator);
    defer positions.deinit();

    try positions.put(.{ .x = start.x, .y = start.y }, {});
    try positions.put(.{ .x = end.x, .y = end.y }, {});

    var graph_iter = graph.keyIterator();
    while (graph_iter.next()) |key| {
        try positions.put(.{ .x = key.x, .y = key.y }, {});
    }

    std.debug.assert(positions.count() <= max_positions);

    const Node = std.bit_set.IntegerBitSet(max_positions);

    var directed: [max_positions]Node = undefined;
    var distance: [max_positions][max_positions]u16 = undefined;

    for (positions.keys(), 0..) |pos, i| {
        var next_set = Node.initEmpty();
        var distances: [max_positions]u16 = undefined;

        inline for (.{ .l, .r, .u, .d }) |dir| {
            if (graph.get(.{ .x = pos.x, .y = pos.y, .dir = dir })) |n| {
                inline for (.{ "a", "b", "c" }) |next_name| {
                    if (@field(n, next_name)) |next| {
                        // std.log.warn("Next {} {}", .{ next.x, next.y });
                        const idx = positions.getIndex(.{ .x = next.x, .y = next.y }).?;
                        next_set.set(idx);
                        distances[idx] = @intCast(next.dist);
                    }
                }
            }
        }

        directed[i] = next_set;
        distance[i] = distances;
    }

    const Path2 = struct {
        curr: Node,
        seen: std.bit_set.IntegerBitSet(max_positions),
        dist: u32,
        curr_idx: u16,
    };

    var queue = std.ArrayList(Path2).init(allocator);
    defer queue.deinit();

    const start_idx: u16 = @intCast(positions.getIndex(.{ .x = start.x, .y = start.y }).?);
    const end_idx: u16 = @intCast(positions.getIndex(end).?);
    const end_idx_mask = @as(u64, 1) << @intCast(end_idx);
    try queue.append(.{ .curr = directed[start_idx], .seen = std.bit_set.IntegerBitSet(max_positions).initEmpty(), .dist = 0, .curr_idx = start_idx });

    var best: u32 = 0;

    while (queue.popOrNull()) |path| {
        var mask = path.curr.mask;
        try queue.ensureUnusedCapacity(@popCount(mask));

        // Move the if statement out of the loop
        if (mask & end_idx_mask != 0) {
            mask ^= end_idx_mask;
            best = @max(best, path.dist + distance[path.curr_idx][end_idx]);
            continue;
        }

        while (mask != 0) {
            const idx = @ctz(mask);
            mask ^= @as(@TypeOf(mask), 1) << @intCast(idx);

            var seen = path.seen;

            if (seen.isSet(idx)) continue;
            seen.set(idx);

            queue.appendAssumeCapacity(.{
                .curr = directed[idx],
                .seen = seen,
                .dist = path.dist + distance[path.curr_idx][idx],
                .curr_idx = idx,
            });
        }
    }

    return best - 1; // Account for off-by-one in path from start to first split
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
fn setAtPos(comptime T: type, x: usize, y: usize, width: usize, buf: [*]T, value: T) void {
    buf[y * width + x] = value;
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
