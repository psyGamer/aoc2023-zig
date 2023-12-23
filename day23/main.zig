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
    try std.testing.expectEqual(@as(u64, 2), try solve(.one, example1, std.testing.allocator));
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

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    _ = part;
    const width = indexOf(u8, in, '\n').?;
    const height = in.len / (width + 1);

    // var line_iter = tokenizeSca(u8, in, '\n');
    // while (line_iter.next()) |line| {
    //     _ = line;
    // }
    // const start: Node = .{ .x = 1, .y = 0, .dir = .d, .g = 0, .f = 0, .visited = std.AutoHashMap(Vec2u, void).init(allocator) };
    const start: Node = .{ .x = 1, .y = 0, .dir = .d, .g = 0, .f = 0, .parent = null };
    const end: Vec2u = .{ .x = @intCast(width - 2), .y = @intCast(height - 1) };

    var goal_dist: u32 = 0;

    var open_set = std.AutoHashMap(NodeState, u32).init(allocator);
    defer open_set.deinit();
    var closed_set = std.AutoHashMap(NodeState, u32).init(allocator);
    defer closed_set.deinit();

    var queue = std.PriorityQueue(Node, void, Node.compare).init(allocator, {});
    defer queue.deinit();

    var visited = std.AutoHashMap(Node, Vec2u).init(allocator);
    defer visited.deinit();

    try queue.add(start);

    search: while (queue.removeOrNull()) |curr| {
        std.debug.assert(!(curr.x == 0 and curr.dir != .r));
        std.debug.assert(!(curr.y == 0 and curr.dir != .d));
        std.debug.assert(!(curr.x == width - 1 and curr.dir != .l));
        std.debug.assert(!(curr.y == height - 1 and curr.dir != .u));

        // std.log.warn("curr {}", .{curr});

        const tile = getAtPos(curr.x, curr.y, width + 1, in);
        const neighbours: [3]?Node = switch (tile) {
            // '>' => .{ if (curr.dir == .l) null else .{ .x = curr.x + 1, .y = curr.y, .dir = .r, .g = undefined, .f = undefined }, null, null },
            // '<' => .{ if (curr.dir == .r) null else .{ .x = curr.x - 1, .y = curr.y, .dir = .l, .g = undefined, .f = undefined }, null, null },
            // 'v' => .{ if (curr.dir == .u) null else .{ .x = curr.x, .y = curr.y + 1, .dir = .d, .g = undefined, .f = undefined }, null, null },
            // '^' => .{ if (curr.dir == .d) null else .{ .x = curr.x, .y = curr.y - 1, .dir = .u, .g = undefined, .f = undefined }, null, null },
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

            // if (neigh.visited.contains(.{ .x = neigh.x, .y = neigh.y })) continue;

            var c: ?*const Node = &curr;
            while (c) |cc| {
                // std.log.warn("{any}", .{c});
                if (cc.x == neigh.x and cc.y == neigh.y) continue :neighbours;
                c = cc.parent;
            }

            neigh.parent = try allocator.create(Node);
            neigh.parent.?.* = curr;
            // std.log.warn("PAR{any}", .{neigh.parent});

            neigh.g = curr.g + 1;
            const h = @abs(end.x - neigh.x) + @abs(end.y - neigh.y);
            neigh.f = neigh.g + h;
            // try neigh.visited.put(.{ .x = curr.x, .y = curr.y }, {});

            // std.log.err("    next {}", .{neigh});

            if (neigh.x == end.x and neigh.y == end.y) {
                if (goal_dist < neigh.g) {
                    goal_dist = neigh.g;
                    // break :search;
                    std.log.err("GOAL HIT {}", .{goal_dist});
                }
                // var c: ?*Node = &neigh;
                // while (c != null) {
                //     std.log.err("   {}", .{c.?.*});
                //     c = c.?.*.parent;
                // }
                continue :search;
            }

            // if (neigh.g >= 155) {
            //     std.log.err("ILLEGAL", .{});
            //     var c: ?*Node = &neigh;
            //     while (c != null) {
            //         std.log.err("   {}", .{c.?.*});
            //         c = c.?.*.parent;
            //     }
            //     break :search;
            // }

            // const state: NodeState = .{ .x = neigh.x, .y = neigh.y, .dir = neigh.dir };
            // const open_gop = try open_set.getOrPut(state);
            // if (!open_gop.found_existing) {
            //     open_gop.value_ptr.* = neigh.f;
            //     try queue.add(neigh);
            // } else if (open_gop.value_ptr.* < neigh.f) {
            //     open_gop.value_ptr.* = neigh.f;
            //     try queue.add(neigh);
            // } else {
            //     continue;
            // }

            try queue.add(neigh);

            // if (closed_set.get(state)) |closed| {
            //     if (closed >= neigh.f) continue;
            // }
        }

        // try closed_set.put(.{ .x = curr.x, .y = curr.y, .dir = curr.dir }, curr.f);
        // var v = @constCast(&curr.visited);
        // v.deinit();
        // if (curr.parent != null) allocator.destroy(curr.parent.?);
    }

    std.log.warn("GOAL {}", .{goal_dist});

    return goal_dist;
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
