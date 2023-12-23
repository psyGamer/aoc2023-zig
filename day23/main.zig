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

    // std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve2(.two, input, allocator)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u64, 2), try solve2(.one, example1, std.testing.allocator));
}
test "Part 2" {
    // try std.testing.expectEqual(@as(u64, 6), try solve(.two, example2, std.testing.allocator));
}

const Dir = enum { l, r, u, d };
const Node = struct {
    x: u16,
    y: u16,
    dir: Dir,

    parent: ?*Node = null,
    // visited: std.AutoHashMap(Vec2u, void),

    g: u32,
    f: u32,

    pub fn compare(_: void, a: Node, b: Node) std.math.Order {
        // When adding, it only checks for != .lt, so .eq and .gt can be treated the same
        if (a.g <= b.g) return .gt;
        return .lt;
    }
};
const Vec2u = struct { x: u16, y: u16 };

const NodeState = struct { x: u16, y: u16, dir: Dir };

const Node2 = struct {
    x: u16,
    y: u16,
    dir: Dir,
    dist: u16,

    pub fn compare(_: void, a: Node2, b: Node2) std.math.Order {
        // When adding, it only checks for != .lt, so .eq and .gt can be treated the same
        if (a.dist <= b.dist) return .gt;
        return .lt;
    }
};

fn subsolve(curr: NodeState, memo: *std.AutoHashMap(NodeState, u64), visited: *std.ArrayList(Vec2u), depth: u64, in: []const u8, width: usize) u64 {
    // if (memo.get(curr)) |c| return c;
    // memo.put(curr, 0) catch unreachable;
    // std.log.warn("curr {} at {}", .{ curr, depth });

    if (curr.y == 0 and curr.dir != .d) return 0;
    if (curr.x == 21 and curr.y == 22) {
        std.log.err("GOAL AT {}", .{depth});
        return depth;
    }

    const new_states: [3]?NodeState = switch (curr.dir) {
        .r => .{
            if (getAtPos(curr.x + 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r },
            if (getAtPos(curr.x, curr.y + 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d },
            if (getAtPos(curr.x, curr.y - 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u },
        },
        .l => .{
            if (getAtPos(curr.x - 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l },
            if (getAtPos(curr.x, curr.y + 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d },
            if (getAtPos(curr.x, curr.y - 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u },
        },
        .u => .{
            if (getAtPos(curr.x + 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r },
            if (getAtPos(curr.x - 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l },
            if (getAtPos(curr.x, curr.y - 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u },
        },
        .d => .{
            if (getAtPos(curr.x + 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r },
            if (getAtPos(curr.x - 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l },
            if (getAtPos(curr.x, curr.y + 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d },
        },
    };

    var result: u64 = 0;

    var clone = visited.clone() catch unreachable;
    defer clone.deinit();

    for (new_states) |state| {
        if (state == null) continue;

        const pos: Vec2u = .{ .x = state.?.x, .y = state.?.y };
        _ = pos;
        // if (visited.contains(pos)) continue;
        // visited.put(pos, {}) catch unreachable;

        result = @max(result, subsolve(state.?, memo, &clone, depth + 1, in, width));
        // break;
    }
    memo.put(curr, result) catch unreachable;
    return result;
}

const NodeDistance = struct { x: u16, y: u16, dir: Dir, dist: u16 };
const Leaf = struct { a: NodeDistance, b: ?NodeDistance, c: ?NodeDistance };

fn buildGraph(curr_state: NodeState, graph: *std.AutoHashMap(NodeState, Leaf), in: []const u8, width: usize, end_point: Vec2u) !NodeDistance {
    // if (graph.get(curr_state)) |result| return result;
    // std.log.warn("start {}", .{curr_state});

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

        // std.log.warn("curr {} {} {} {} {}", .{ curr, left, right, up, down });

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

const Path = struct { x: u16, y: u16, dir: Dir, dist: u32, visited: std.AutoArrayHashMap(Vec2u, void) };

pub fn solve2(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    const width = indexOf(u8, in, '\n').?;
    const height = in.len / (width + 1);
    _ = part;
    const start: NodeState = .{ .x = 1, .y = 0, .dir = .d };
    const end: Vec2u = .{ .x = @intCast(width - 2), .y = @intCast(height - 1) };

    var graph = std.AutoHashMap(NodeState, Leaf).init(allocator);
    defer graph.deinit();

    const start_path = try buildGraph(.{ .x = start.x, .y = start.y, .dir = .d }, &graph, in, width + 1, end);
    try graph.put(start, .{ .a = start_path, .b = null, .c = null });

    // var iter = graph.keyIterator();
    // while (iter.next()) |key| {
    //     std.log.warn("{}: {}", .{ key, graph.get(key.*).? });
    // }
    // if (true) return 0;

    var map = std.AutoHashMap(NodeState, u16).init(allocator);
    defer map.deinit();

    var queue = std.ArrayList(Path).init(allocator);
    defer queue.deinit();
    try queue.append(.{ .x = start.x, .y = start.y, .dir = start.dir, .dist = 0, .visited = std.AutoArrayHashMap(Vec2u, void).init(allocator) });

    var best: u32 = 0;

    while (queue.items.len > 0) {
        var curr = queue.items[queue.items.len - 1];
        queue.items.len -= 1;

        // std.log.warn("curr {}", .{curr});

        if (curr.x == end.x and curr.y == end.y) {
            if (curr.dist > best) {
                best = curr.dist;
                std.log.err("GOAL {}", .{best});
            }
            continue;
        }

        const pos: Vec2u = .{ .x = curr.x, .y = curr.y };
        try curr.visited.put(pos, {});

        const leaf = graph.get(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }).?;
        // std.log.warn("    next {}", .{leaf});
        // std.log.warn("    visited:", .{});
        // var iter2 = curr.visited.keyIterator();
        // while (iter2.next()) |key| {
        //     std.log.warn("    - {}", .{key});
        // }
        // for (curr.visited.keys()) |key| {
        //     std.log.warn("    - {}", .{key});
        // }

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

    return best - 1;
}

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    _ = part;
    const width = indexOf(u8, in, '\n').?;
    const height = in.len / (width + 1);

    // var memo = std.AutoHashMap(NodeState, u64).init(allocator);
    // defer memo.deinit();

    // var visited = std.AutoHashMap(Vec2u, void).init(allocator);
    // defer visited.deinit();

    // return subsolve(.{ .x = 1, .y = 0, .dir = .d }, &memo, &visited, 0, in, width);

    var map = try Array2D(u16).initWithDefault(allocator, width, height, 0);
    defer map.deinit(allocator);

    var queue = std.ArrayList(Node2).init(allocator);
    defer queue.deinit();
    // var queue = std.PriorityQueue(Node2, void, Node2.compare).init(allocator, {});
    // defer queue.deinit();

    // try queue.add(.{ .x = @intCast(width - 2), .y = @intCast(height - 1), .dir = .u, .dist = 1000 });
    try queue.append(.{ .x = @intCast(width - 2), .y = @intCast(height - 1), .dir = .u, .dist = 1000 });

    var next = std.ArrayList(Node2).init(allocator);
    defer next.deinit();

    var best: u32 = 0;

    var i: usize = 0;
    outer: while (queue.popOrNull()) |curr_node| : (i += 1) {
        // outer: while (queue.removeOrNull()) |curr_node| : (i += 1) {
        var curr = curr_node;
        map.set(curr.x, curr.y, curr.dist);
        std.log.warn("curr {} {} {}", .{ curr, width, height });

        while (true) {
            std.log.warn("    next {} ", .{curr});
            if (map.get(curr.x, curr.y) == 0) map.set(curr.x, curr.y, 9999 - @as(u16, @intCast(i)));
            if (curr.y == height - 1 and curr.dir == .d) continue :outer;
            if (curr.y == 0 and curr.dir == .u) {
                std.log.warn("NEW BEST {}", .{curr.dist});
                best = @max(best, curr.dist);
                continue :outer;
            }
            if (curr.dir != .l and getAtPos(curr.x + 1, curr.y, width + 1, in) != '#' and map.get(curr.x + 1, curr.y) == 0) try next.append(.{ .x = curr.x + 1, .y = curr.y, .dir = .r, .dist = curr.dist + 1 });
            if (curr.dir != .r and getAtPos(curr.x - 1, curr.y, width + 1, in) != '#' and map.get(curr.x - 1, curr.y) == 0) try next.append(.{ .x = curr.x - 1, .y = curr.y, .dir = .l, .dist = curr.dist + 1 });
            if (curr.dir != .u and getAtPos(curr.x, curr.y + 1, width + 1, in) != '#' and map.get(curr.x, curr.y + 1) == 0) try next.append(.{ .x = curr.x, .y = curr.y + 1, .dir = .d, .dist = curr.dist + 1 });
            if (curr.dir != .d and getAtPos(curr.x, curr.y - 1, width + 1, in) != '#' and map.get(curr.x, curr.y - 1) == 0) try next.append(.{ .x = curr.x, .y = curr.y - 1, .dir = .u, .dist = curr.dist + 1 });

            if (next.items.len == 1) {
                curr = next.items[0];
                next.clearRetainingCapacity();
            } else {
                break;
            }
        }

        std.log.warn("    next => {any} ", .{next.items});
        try queue.appendSlice(next.items);
        // try queue.insertSlice(0, next.items);
        // try queue.addSlice(next.items);
        next.clearRetainingCapacity();
    }

    std.log.warn("\n{d:0>3}", .{map});
    return best;

    // var line_iter = tokenizeSca(u8, in, '\n');
    // while (line_iter.next()) |line| {
    //     _ = line;
    // }
    // const start: Node = .{ .x = 1, .y = 0, .dir = .d, .g = 0, .f = 0, .visited = std.AutoHashMap(Vec2u, void).init(allocator) };
    // const start: Node = .{ .x = 1, .y = 0, .dir = .d, .g = 0, .f = 0, .parent = null };
    // const end: Vec2u = .{ .x = @intCast(width - 2), .y = @intCast(height - 1) };

    // var goal_dist: u32 = 0;

    // var open_set = std.AutoHashMap(NodeState, u32).init(allocator);
    // defer open_set.deinit();
    // var closed_set = std.AutoHashMap(NodeState, u32).init(allocator);
    // defer closed_set.deinit();

    // var queue = std.PriorityQueue(Node, void, Node.compare).init(allocator, {});
    // defer queue.deinit();

    // var visited = std.AutoHashMap(Node, Vec2u).init(allocator);
    // defer visited.deinit();

    // try queue.add(start);

    // search: while (queue.removeOrNull()) |curr| {
    //     std.debug.assert(!(curr.x == 0 and curr.dir != .r));
    //     std.debug.assert(!(curr.y == 0 and curr.dir != .d));
    //     std.debug.assert(!(curr.x == width - 1 and curr.dir != .l));
    //     std.debug.assert(!(curr.y == height - 1 and curr.dir != .u));

    //     // std.log.warn("curr {}", .{curr});

    //     const tile = getAtPos(curr.x, curr.y, width + 1, in);
    //     const neighbours: [3]?Node = switch (tile) {
    //         // '>' => .{ if (curr.dir == .l) null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r, .g = undefined, .f = undefined }, null, null },
    //         // '<' => .{ if (curr.dir == .r) null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l, .g = undefined, .f = undefined }, null, null },
    //         // 'v' => .{ if (curr.dir == .u) null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d, .g = undefined, .f = undefined }, null, null },
    //         // '^' => .{ if (curr.dir == .d) null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u, .g = undefined, .f = undefined }, null, null },
    //         else => switch (curr.dir) {
    //             .r => .{
    //                 if (getAtPos(curr.x + 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r, .g = undefined, .f = undefined },
    //                 if (getAtPos(curr.x, curr.y + 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d, .g = undefined, .f = undefined },
    //                 if (getAtPos(curr.x, curr.y - 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u, .g = undefined, .f = undefined },
    //             },
    //             .l => .{
    //                 if (getAtPos(curr.x - 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l, .g = undefined, .f = undefined },
    //                 if (getAtPos(curr.x, curr.y + 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d, .g = undefined, .f = undefined },
    //                 if (getAtPos(curr.x, curr.y - 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u, .g = undefined, .f = undefined },
    //             },
    //             .u => .{
    //                 if (getAtPos(curr.x + 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r, .g = undefined, .f = undefined },
    //                 if (getAtPos(curr.x - 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l, .g = undefined, .f = undefined },
    //                 if (getAtPos(curr.x, curr.y - 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u, .g = undefined, .f = undefined },
    //             },
    //             .d => .{
    //                 if (getAtPos(curr.x + 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r, .g = undefined, .f = undefined },
    //                 if (getAtPos(curr.x - 1, curr.y, width + 1, in) == '#') null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l, .g = undefined, .f = undefined },
    //                 if (getAtPos(curr.x, curr.y + 1, width + 1, in) == '#') null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d, .g = undefined, .f = undefined },
    //             },
    //         },
    //     };

    //     neighbours: for (&neighbours) |neighbour| {
    //         if (neighbour == null) continue;
    //         var neigh: Node = neighbour.?;

    //         // if (neigh.visited.contains(.{ .x = neigh.x, .y = neigh.y })) continue;

    //         var c: ?*const Node = &curr;
    //         while (c) |cc| {
    //             // std.log.warn("{any}", .{c});
    //             if (cc.x == neigh.x and cc.y == neigh.y) continue :neighbours;
    //             c = cc.parent;
    //         }

    //         neigh.parent = try allocator.create(Node);
    //         neigh.parent.?.* = curr;
    //         // std.log.warn("PAR{any}", .{neigh.parent});

    //         neigh.g = curr.g + 1;
    //         const h = @abs(end.x - neigh.x) + @abs(end.y - neigh.y);
    //         neigh.f = neigh.g + h;
    //         // try neigh.visited.put(.{ .x = curr.x, .y = curr.y }, {});

    //         // std.log.err("    next {}", .{neigh});

    //         if (neigh.x == end.x and neigh.y == end.y) {
    //             if (goal_dist < neigh.g) {
    //                 goal_dist = neigh.g;
    //                 // break :search;
    //                 std.log.err("GOAL HIT {}", .{goal_dist});
    //             }
    //             // var c: ?*Node = &neigh;
    //             // while (c != null) {
    //             //     std.log.err("   {}", .{c.?.*});
    //             //     c = c.?.*.parent;
    //             // }
    //             continue :search;
    //         }

    //         // if (neigh.g >= 155) {
    //         //     std.log.err("ILLEGAL", .{});
    //         //     var c: ?*Node = &neigh;
    //         //     while (c != null) {
    //         //         std.log.err("   {}", .{c.?.*});
    //         //         c = c.?.*.parent;
    //         //     }
    //         //     break :search;
    //         // }

    //         // const state: NodeState = .{ .x = neigh.x, .y = neigh.y, .dir = neigh.dir };
    //         // const open_gop = try open_set.getOrPut(state);
    //         // if (!open_gop.found_existing) {
    //         //     open_gop.value_ptr.* = neigh.f;
    //         //     try queue.add(neigh);
    //         // } else if (open_gop.value_ptr.* < neigh.f) {
    //         //     open_gop.value_ptr.* = neigh.f;
    //         //     try queue.add(neigh);
    //         // } else {
    //         //     continue;
    //         // }

    //         try queue.add(neigh);

    //         // if (closed_set.get(state)) |closed| {
    //         //     if (closed >= neigh.f) continue;
    //         // }
    //     }

    //     // try closed_set.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, curr.f);
    //     // var v = @constCast(&curr.visited);
    //     // v.deinit();
    //     // if (curr.parent != null) allocator.destroy(curr.parent.?);
    // }

    // std.log.warn("GOAL {}", .{goal_dist});

    // return goal_dist;
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
    // std.log.warn("at {} {} = {c}", .{ x, y, buf[y * width + x] });
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
