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

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, &arena)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, &arena)});
}
test "Part 1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    try std.testing.expectEqual(@as(u64, 94), try solve(.one, example1, &arena));
}
test "Part 2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    try std.testing.expectEqual(@as(u64, 154), try solve(.two, example1, &arena));
}

const Dir = enum { l, r, u, d };

// Part 1
const Node = struct {
    x: u16,
    y: u16,
    dir: Dir,

    parent: ?*Node = null,

    g: u32,
    f: u32,

    pub fn compare(_: void, a: Node, b: Node) std.math.Order {
        // When adding, it only checks for != .lt, so .eq and .gt can be treated the same
        if (a.g <= b.g) return .gt;
        return .lt;
    }
};
const Vec2u = struct { x: u16, y: u16 };

// Part 2
const NodeState = struct { x: u16, y: u16, dir: Dir };
const NodeDistance = struct { x: u16, y: u16, dir: Dir, dist: u16 };
const Leaf = struct { a: NodeDistance, b: ?NodeDistance, c: ?NodeDistance };
const Path = struct { x: u16, y: u16, dir: Dir, dist: u32, visited: std.AutoArrayHashMap(Vec2u, void) };

fn buildGraph(curr_state: NodeState, graph: *std.AutoHashMap(NodeState, Leaf), in: []const u8, width: usize, end_point: Vec2u) !NodeDistance {
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
                    .a = try buildGraph(.{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                    .b = try buildGraph(.{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                    .c = try buildGraph(.{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (left and right and up) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(.{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                    .b = try buildGraph(.{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                    .c = try buildGraph(.{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (up and down and left) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(.{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                    .b = try buildGraph(.{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                    .c = try buildGraph(.{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (up and down and right) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(.{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                    .b = try buildGraph(.{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                    .c = try buildGraph(.{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        }

        if (right and left) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(.{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                    .b = try buildGraph(.{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (up and down) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(.{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                    .b = try buildGraph(.{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (up and right) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(.{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                    .b = try buildGraph(.{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (up and left) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(.{ .x = curr.x, .y = curr.y - 1, .dir = .u }, graph, in, width, end_point),
                    .b = try buildGraph(.{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (down and right) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(.{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                    .b = try buildGraph(.{ .x = curr.x + 1, .y = curr.y, .dir = .r }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        } else if (down and left) {
            if (!graph.contains(.{ .x = curr.x, .y = curr.y, .dir = curr.dir })) {
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, undefined); // Mark this node as already containing something
                try graph.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, .{
                    .a = try buildGraph(.{ .x = curr.x, .y = curr.y + 1, .dir = .d }, graph, in, width, end_point),
                    .b = try buildGraph(.{ .x = curr.x - 1, .y = curr.y, .dir = .l }, graph, in, width, end_point),
                    .c = null,
                });
            }
            return .{ .x = curr.x, .y = curr.y, .dir = curr.dir, .dist = dist };
        }

        if (left) {
            curr.dir = .l;
            curr.x -= 1;
            continue;
        } else if (right) {
            curr.dir = .r;
            curr.x += 1;
            continue;
        } else if (up) {
            curr.dir = .u;
            curr.y -= 1;
            continue;
        } else if (down) {
            curr.dir = .d;
            curr.y += 1;
            continue;
        }
        unreachable;
    }
}

pub fn solve(comptime part: Part, in: []const u8, arena: *std.heap.ArenaAllocator) !u64 {
    const width = indexOf(u8, in, '\n').?;
    const height = in.len / (width + 1);

    const allocator = arena.allocator();

    var best: u32 = 0;

    if (part == .one) {
        const start: Node = .{ .x = 1, .y = 0, .dir = .d, .g = 0, .f = 0, .parent = null };
        const end: Vec2u = .{ .x = @intCast(width - 2), .y = @intCast(height - 1) };

        var queue = std.PriorityQueue(Node, void, Node.compare).init(allocator, {});
        try queue.add(start);

        search: while (queue.removeOrNull()) |curr| {
            std.debug.assert(!(curr.x == 0 and curr.dir != .r));
            std.debug.assert(!(curr.y == 0 and curr.dir != .d));
            std.debug.assert(!(curr.x == width - 1 and curr.dir != .l));
            std.debug.assert(!(curr.y == height - 1 and curr.dir != .u));

            const tile = getAtPos(curr.x, curr.y, width + 1, in);
            const neighbours: [3]?Node = switch (tile) {
                '>' => .{ if (curr.dir == .l) null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r, .g = undefined, .f = undefined }, null, null },
                '<' => .{ if (curr.dir == .r) null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l, .g = undefined, .f = undefined }, null, null },
                'v' => .{ if (curr.dir == .u) null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d, .g = undefined, .f = undefined }, null, null },
                '^' => .{ if (curr.dir == .d) null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u, .g = undefined, .f = undefined }, null, null },
                else => switch (curr.dir) {
                    .r => .{
                        if (getAtPos(curr.x + 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r, .g = undefined, .f = undefined },
                        if (getAtPos(curr.x, curr.y + 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d, .g = undefined, .f = undefined },
                        if (getAtPos(curr.x, curr.y - 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u, .g = undefined, .f = undefined },
                    },
                    .l => .{
                        if (getAtPos(curr.x - 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l, .g = undefined, .f = undefined },
                        if (getAtPos(curr.x, curr.y + 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d, .g = undefined, .f = undefined },
                        if (getAtPos(curr.x, curr.y - 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u, .g = undefined, .f = undefined },
                    },
                    .u => .{
                        if (getAtPos(curr.x + 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r, .g = undefined, .f = undefined },
                        if (getAtPos(curr.x - 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l, .g = undefined, .f = undefined },
                        if (getAtPos(curr.x, curr.y - 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u, .g = undefined, .f = undefined },
                    },
                    .d => .{
                        if (getAtPos(curr.x + 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r, .g = undefined, .f = undefined },
                        if (getAtPos(curr.x - 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l, .g = undefined, .f = undefined },
                        if (getAtPos(curr.x, curr.y + 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d, .g = undefined, .f = undefined },
                    },
                },
            };

            neighbours: for (&neighbours) |neighbour| {
                if (neighbour == null) continue;
                var neigh: Node = neighbour.?;

                var c: ?*const Node = &curr;
                while (c) |cc| {
                    if (cc.x == neigh.x and cc.y == neigh.y) continue :neighbours;
                    c = cc.parent;
                }

                neigh.parent = try allocator.create(Node);
                neigh.parent.?.* = curr;

                neigh.g = curr.g + 1;
                const h = @abs(end.x - neigh.x) + @abs(end.y - neigh.y);
                neigh.f = neigh.g + h;

                if (neigh.x == end.x and neigh.y == end.y) {
                    best = @max(best, neigh.g);
                    continue :search;
                }
                try queue.add(neigh);
            }
        }
    } else if (part == .two) {
        const start: NodeState = .{ .x = 1, .y = 0, .dir = .d };
        const end: Vec2u = .{ .x = @intCast(width - 2), .y = @intCast(height - 1) };

        var graph = std.AutoHashMap(NodeState, Leaf).init(allocator);
        const start_path = try buildGraph(.{ .x = start.x, .y = start.y, .dir = .d }, &graph, in, width + 1, end);
        try graph.put(start, .{ .a = start_path, .b = null, .c = null });

        var queue = std.ArrayList(Path).init(allocator);
        try queue.append(.{ .x = start.x, .y = start.y, .dir = start.dir, .dist = 0, .visited = std.AutoArrayHashMap(Vec2u, void).init(allocator) });

        while (queue.items.len > 0) {
            var curr = queue.items[queue.items.len - 1];
            queue.items.len -= 1;

            if (curr.x == end.x and curr.y == end.y) {
                best = @max(best, curr.dist);
                continue;
            }

            const pos: Vec2u = .{ .x = curr.x, .y = curr.y };
            try curr.visited.put(pos, {});

            const leaf = graph.get(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }).?;

            if (!curr.visited.contains(.{ .x = leaf.a.x, .y = leaf.a.y })) {
                try queue.append(.{ .x = leaf.a.x, .y = leaf.a.y, .dir = leaf.a.dir, .dist = curr.dist + leaf.a.dist, .visited = try curr.visited.clone() });
            }
            if (leaf.b != null and !curr.visited.contains(.{ .x = leaf.b.?.x, .y = leaf.b.?.y })) {
                try queue.append(.{ .x = leaf.b.?.x, .y = leaf.b.?.y, .dir = leaf.b.?.dir, .dist = curr.dist + leaf.b.?.dist, .visited = try curr.visited.clone() });
            }
            if (leaf.c != null and !curr.visited.contains(.{ .x = leaf.c.?.x, .y = leaf.c.?.y })) {
                try queue.append(.{ .x = leaf.c.?.x, .y = leaf.c.?.y, .dir = leaf.c.?.dir, .dist = curr.dist + leaf.c.?.dist, .visited = try curr.visited.clone() });
            }
        }

        best -= 1; // Account for off-by-one in path from start to first split
    }

    return best;
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
