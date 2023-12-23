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

fn Path(comptime max_position: comptime_int, comptime Index: type, comptime Dist: type) type {
    return struct {
        curr_idx: Index,
        dist: Dist,
        visited: std.bit_set.IntegerBitSet(max_position),
    };
}

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
    const start_path = try buildGraph(part, .{ .x = start.x, .y = start.y, .dir = .d }, &graph, in, width + 1, end);
    try graph.put(start, .{ .a = start_path, .b = null, .c = null });

    const dir_count = std.math.maxInt(std.meta.Tag(Dir)) + 1;
    const max_positions = 46;
    const max_nodes = max_positions * dir_count;

    // Assert that all node-positions fit
    var positions = std.AutoArrayHashMap(Vec2u, void).init(allocator);
    defer positions.deinit();

    var graph_iter = graph.keyIterator();
    while (graph_iter.next()) |key| {
        try positions.put(.{ .x = key.x, .y = key.y }, {});
    }

    std.debug.assert(positions.count() < max_positions - 1);
    std.debug.assert(graph.count() < max_nodes);

    const Index = packed struct(u8) {
        dir: Dir,
        pos_idx: u6,
    };

    const invalid_pos_index = max_positions - 1;
    const invalid_index: Index = .{ .pos_idx = invalid_pos_index, .dir = undefined };
    const DistInt = u16;

    const IndexLeaf = struct {
        a_idx: Index = invalid_index,
        b_idx: Index = invalid_index,
        c_idx: Index = invalid_index,
        a_dist: DistInt = undefined,
        b_dist: DistInt = undefined,
        c_dist: DistInt = undefined,
    };

    // Flatten the graph into an array
    // TODO: Just use an array hash map for the graph?
    try positions.put(.{ .x = start.x, .y = start.y }, {});
    try positions.put(.{ .x = end.x, .y = end.y }, {});

    // Make sure our tricks work
    std.debug.assert(@as(u8, @bitCast(Index{ .pos_idx = 0, .dir = .l })) == 0);
    std.debug.assert(@as(u8, @bitCast(Index{ .pos_idx = 0, .dir = .r })) == 1);
    std.debug.assert(@as(u8, @bitCast(Index{ .pos_idx = 0, .dir = .u })) == 2);
    std.debug.assert(@as(u8, @bitCast(Index{ .pos_idx = 0, .dir = .d })) == 3);

    var flattened: [max_nodes]IndexLeaf = [_]IndexLeaf{undefined} ** max_nodes;
    for (positions.keys(), 0..) |pos, i| {
        for (0..dir_count) |j| {
            const dir: Dir = @enumFromInt(j);
            if (graph.get(.{ .x = pos.x, .y = pos.y, .dir = dir })) |value| {
                flattened[4 * i + j] = .{
                    .a_idx = if (value.a != null) .{ .pos_idx = @intCast(positions.getIndex(.{ .x = value.a.?.x, .y = value.a.?.y }) orelse invalid_pos_index), .dir = value.a.?.dir } else invalid_index,
                    .b_idx = if (value.b != null) .{ .pos_idx = @intCast(positions.getIndex(.{ .x = value.b.?.x, .y = value.b.?.y }) orelse invalid_pos_index), .dir = value.b.?.dir } else invalid_index,
                    .c_idx = if (value.c != null) .{ .pos_idx = @intCast(positions.getIndex(.{ .x = value.c.?.x, .y = value.c.?.y }) orelse invalid_pos_index), .dir = value.c.?.dir } else invalid_index,
                    .a_dist = if (value.a != null) value.a.?.dist else undefined,
                    .b_dist = if (value.b != null) value.b.?.dist else undefined,
                    .c_dist = if (value.c != null) value.c.?.dist else undefined,
                };
            } else {
                flattened[4 * i + j] = .{
                    .a_idx = invalid_index,
                    .b_idx = invalid_index,
                    .c_idx = invalid_index,
                    .a_dist = undefined,
                    .b_dist = undefined,
                    .c_dist = undefined,
                };
            }
        }
    }

    const start_idx: Index = .{ .pos_idx = @intCast(positions.getIndex(.{ .x = start.x, .y = start.y }).?), .dir = .d };
    const end_idx: Index = .{ .pos_idx = @intCast(positions.getIndex(.{ .x = end.x, .y = end.y }).?), .dir = .d };
    var init_visited = std.bit_set.IntegerBitSet(max_positions).initEmpty();
    init_visited.set(invalid_pos_index); // Mark invalid indices as visited so they don't get indexed

    var queue = std.ArrayList(Path(max_positions, Index, DistInt)).init(allocator);
    try queue.ensureTotalCapacity(max_nodes * 2); // Preallocate a bit
    queue.appendAssumeCapacity(.{ .curr_idx = start_idx, .dist = 0, .visited = init_visited });

    var best: u32 = 0;

    while (queue.items.len > 0) {
        var curr = queue.items[queue.items.len - 1];
        queue.items[queue.items.len - 1] = undefined;
        queue.items.len -= 1;

        if (@as(u8, @bitCast(curr.curr_idx)) == @as(u8, @bitCast(end_idx))) {
            best = @max(best, curr.dist);
            continue;
        }

        const leaf = flattened[@as(u8, @bitCast(curr.curr_idx))];

        curr.visited.set(curr.curr_idx.pos_idx);
        if (!curr.visited.isSet(leaf.a_idx.pos_idx)) {
            // try queue.append(.{ .curr_idx = leaf.a_idx, .dist = curr.dist + leaf.a_dist, .visited = curr.visited });
            fastArrayListAppend(Path(max_positions, Index, DistInt), &queue, .{ .curr_idx = leaf.a_idx, .dist = curr.dist + leaf.a_dist, .visited = curr.visited });
        }
        if (!curr.visited.isSet(leaf.b_idx.pos_idx)) {
            // try queue.append(.{ .curr_idx = leaf.b_idx, .dist = curr.dist + leaf.b_dist, .visited = curr.visited });
            fastArrayListAppend(Path(max_positions, Index, DistInt), &queue, .{ .curr_idx = leaf.b_idx, .dist = curr.dist + leaf.b_dist, .visited = curr.visited });
        }
        if (!curr.visited.isSet(leaf.c_idx.pos_idx)) {
            // try queue.append(.{ .curr_idx = leaf.c_idx, .dist = curr.dist + leaf.c_dist, .visited = curr.visited });
            fastArrayListAppend(Path(max_positions, Index, DistInt), &queue, .{ .curr_idx = leaf.c_idx, .dist = curr.dist + leaf.c_dist, .visited = curr.visited });
        }
    }

    return best - 1; // Account for off-by-one in path from start to first split
}

// Inlines ArrayList appension + ignores the errors
inline fn fastArrayListAppend(comptime T: type, list: *std.ArrayList(T), item: T) void {
    list.ensureTotalCapacity(list.items.len + 1) catch unreachable;

    const new_item_ptr = list.addOneAssumeCapacity();
    new_item_ptr.* = item;
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
