const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const builtin = @import("builtin");

pub const input = @embedFile("input.txt");
const example1 = @embedFile("example1.txt");
const example2 = @embedFile("example2.txt");

pub const std_options: std.Options = .{
    .log_level = .info,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Result (Part 1): {}", .{try solve(input, allocator)});
    std.log.info("Result (Part 2): {s}", .{"Merry Christmas"});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u64, 2), try solve(example1, std.testing.allocator));
}

// const Node = struct {
//     const max_graph_size = 2048;

//     idx: u16,
//     dist: u16,
//     visited: std.StaticBitSet(max_graph_size),

//     pub fn compare(_: void, lhs: Node, rhs: Node) std.math.Order {
//         // When adding, it only checks for != .lt, so .eq and .gt can be treated the same
//         if (lhs.dist >= rhs.dist) return .gt;
//         return .lt;
//     }
// };

pub fn solve(in: []const u8, allocator: Allocator) !u64 {
    var unoptimized_graph = std.StringArrayHashMap(std.ArrayList([]const u8)).init(allocator);
    defer {
        for (unoptimized_graph.values()) |v| {
            v.deinit();
        }
        unoptimized_graph.deinit();
    }

    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| {
        const name = line[0..3];

        var target_iter = splitSca(u8, line["abc: ".len..], ' ');
        while (target_iter.next()) |target| {
            const gop = try unoptimized_graph.getOrPut(name);
            if (!gop.found_existing) {
                gop.value_ptr.* = std.ArrayList([]const u8).init(allocator);
            }

            try gop.value_ptr.append(target);

            const gop2 = try unoptimized_graph.getOrPut(target);
            if (!gop2.found_existing) {
                gop2.value_ptr.* = std.ArrayList([]const u8).init(allocator);
            }
            try gop2.value_ptr.append(name);
        }
    }

    // If every node has at least 4 edges, doing 3 BFSs which remove visited nodes still leaves 1 possible connection
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
        var min: usize = std.math.maxInt(usize);
        for (unoptimized_graph.values()) |v| {
            min = @min(min, v.items.len);
        }
        std.debug.assert(min >= 4);
    }

    var seed: u64 = undefined;
    const seed_buf = std.mem.asBytes(&seed);
    _ = std.c.getrandom(seed_buf.ptr, seed_buf.len, 0);

    var rng = std.rand.Xoroshiro128.init(seed);

    const graph = try allocator.alloc([]u16, unoptimized_graph.count());
    defer {
        for (unoptimized_graph.values(), graph) |values, *v| {
            // We remove more and more values from this slice over time, so the .len will be inaccurate
            v.len = values.items.len;
            allocator.free(v.*);
        }
        allocator.free(graph);
    }

    for (unoptimized_graph.values(), graph) |v, *g| {
        g.* = try allocator.alloc(u16, v.items.len);
        for (v.items, 0..) |n, j| {
            g.*[j] = @intCast(unoptimized_graph.getIndex(n).?);
        }
    }

    const Node = struct { idx: u16, prev_idx: u16, dist: u16 };

    var queue = std.ArrayList(Node).init(allocator);
    defer queue.deinit();
    var floodfill_queue = std.ArrayList(u16).init(allocator);
    defer floodfill_queue.deinit();

    const dist = try allocator.alloc(u16, graph.len);
    defer allocator.free(dist);
    const prev = try allocator.alloc(u16, graph.len);
    defer allocator.free(prev);
    const visited = try allocator.alloc(bool, graph.len);
    defer allocator.free(visited);

    while (true) {
        const start_idx: u16 = @intCast(rng.next() % (graph.len - 1));

        for (0..3) |_| {
            queue.clearRetainingCapacity();
            try queue.append(.{ .idx = start_idx, .prev_idx = std.math.maxInt(u16), .dist = 0 });

            @memset(dist, std.math.maxInt(u16));
            @memset(prev, std.math.maxInt(u16));

            var max_dist: u16 = 0;
            var max_dist_idx: u16 = undefined;

            while (queue.popOrNull()) |curr| {
                if (dist[curr.idx] <= curr.dist) continue;
                dist[curr.idx] = curr.dist;
                prev[curr.idx] = curr.prev_idx;

                if (curr.dist > max_dist) {
                    max_dist = curr.dist;
                    max_dist_idx = curr.idx;
                }

                const next = graph[curr.idx];
                try queue.ensureUnusedCapacity(next.len);
                for (next) |n| {
                    queue.appendAssumeCapacity(.{ .idx = n, .prev_idx = curr.idx, .dist = curr.dist + 1 });
                }
            }

            // Remove the path from the graph
            var curr_idx = max_dist_idx;
            while (true) {
                const next_idx = prev[curr_idx];
                if (next_idx == std.math.maxInt(u16)) break;

                _ = swapRemove(u16, &graph[curr_idx], indexOf(u16, graph[curr_idx], next_idx).?);
                _ = swapRemove(u16, &graph[next_idx], indexOf(u16, graph[next_idx], curr_idx).?);

                curr_idx = next_idx;
            }
        }

        // Floodfill from the starting node. If the two sets are now seperated, this should result in a set size of != all nodes.
        floodfill_queue.clearRetainingCapacity();
        try floodfill_queue.append(start_idx);

        @memset(visited, false);

        var set_size_a: u16 = 0;

        while (floodfill_queue.popOrNull()) |curr_idx| {
            if (visited[curr_idx]) continue;
            visited[curr_idx] = true;
            set_size_a += 1;

            const next = graph[curr_idx];
            try floodfill_queue.ensureUnusedCapacity(next.len);
            for (next) |n| {
                floodfill_queue.appendAssumeCapacity(n);
            }
        }

        if (set_size_a == graph.len) continue;
        const set_size_b = graph.len - set_size_a;

        return set_size_a * set_size_b;
    }
}

fn swapRemove(comptime T: type, buffer: *[]T, index: usize) T {
    const item = buffer.*[index];
    buffer.*[index] = buffer.*[buffer.len - 1];
    buffer.len -= 1;
    return item;
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
