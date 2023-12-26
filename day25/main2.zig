const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

pub const input = @embedFile("input.txt");
const example1 = @embedFile("example1.txt");
const example2 = @embedFile("example2.txt");

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
    try std.testing.expectEqual(@as(u64, 6), try solve(.two, example2, std.testing.allocator));
}

const Node = struct {
    name: []const u8,
    dist: u32,
    visited: std.StringArrayHashMap(void),

    pub fn compare(__: void, lhs: Node, rhs: Node) std.math.Order {
        _ = __;
        if (lhs.dist >= rhs.dist) return .gt;
        return .lt;
    }
};
fn shortestPath(allocator: Allocator, a: []const u8, b: []const u8, graph: std.StringArrayHashMap(std.ArrayList([]const u8))) ![][]const u8 {
    std.log.warn("search {s} {s}", .{ a, b });

    // var visited = std.StringHashMap(void).init(allocator);
    var queue = std.PriorityQueue(Node, void, Node.compare).init(allocator, {});

    // try queue.add(.{ .name = a, .prev = "", .dist = 0 });
    try queue.add(.{ .name = a, .visited = std.StringArrayHashMap(void).init(allocator), .dist = 0 });
    while (queue.removeOrNull()) |immut_curr| {

        // while (queue.items.len > 0) {
        var curr = immut_curr;
        // std.log.warn("curr {s} {s} {}", .{ a, curr.name, curr });
        // if (visited.contains(curr.name)) continue;
        // try visited.put(curr.name, {});
        if (curr.visited.contains(curr.name)) continue;
        try curr.visited.put(curr.name, {});
        if (std.mem.eql(u8, curr.name, b)) return curr.visited.keys();
        const next = graph.get(curr.name).?.items;
        for (next) |n| {
            try queue.add(.{ .name = n, .visited = try curr.visited.clone(), .dist = curr.dist + 1 });
        }
    }
    unreachable;
}

const PathSort = struct {
    entries: []usize,
    pub fn lessThan(ctx: PathSort, a: usize, b: usize) bool {
        return ctx.entries[a] > ctx.entries[b];
    }
};

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    _ = part;

    var graph = std.StringArrayHashMap(std.ArrayList([]const u8)).init(allocator);
    defer {
        for (graph.values()) |v| {
            v.deinit();
        }
        graph.deinit();
    }
    var double_graph = std.StringArrayHashMap(std.ArrayList([]const u8)).init(allocator);
    defer {
        for (double_graph.values()) |v| {
            v.deinit();
        }
        double_graph.deinit();
    }

    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| {
        const name = line[0..3];

        var target_iter = splitSca(u8, line["abc: ".len..], ' ');
        while (target_iter.next()) |target| {
            const gop = try graph.getOrPut(name);
            if (!gop.found_existing) {
                gop.value_ptr.* = std.ArrayList([]const u8).init(allocator);
            }

            try gop.value_ptr.append(target);

            const gop2 = try double_graph.getOrPut(name);
            if (!gop2.found_existing) {
                gop2.value_ptr.* = std.ArrayList([]const u8).init(allocator);
            }

            try gop2.value_ptr.append(target);

            const gop3 = try double_graph.getOrPut(target);
            if (!gop3.found_existing) {
                gop3.value_ptr.* = std.ArrayList([]const u8).init(allocator);
            }
            try gop3.value_ptr.append(name);
        }
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator2 = arena.allocator();

    var seed: u64 = undefined;
    try std.os.getrandom(std.mem.asBytes(&seed));

    var rng = std.rand.DefaultPrng.init(seed);
    const random = rng.random();
    const keys = double_graph.keys();

    const Path = struct { a: []const u8, b: []const u8 };
    // var common = StrMap(usize).init(allocator);
    var common = std.ArrayHashMap(Path, usize, SliceHashmapCtx(Path), false).init(allocator);

    for (0..500) |_| {
        const a_idx = random.uintAtMost(usize, keys.len - 1);
        const b_idx = random.uintAtMost(usize, keys.len - 1);
        const path = try shortestPath(allocator2, keys[a_idx], keys[b_idx], double_graph);
        for (1..path.len) |i| {
            const gop = try common.getOrPut(.{
                .a = path[i - 1],
                .b = path[i],
            });
            if (!gop.found_existing) {
                gop.value_ptr.* = 0;
            }
            gop.value_ptr.* += 1;
        }
        _ = arena.reset(.retain_capacity);
    }

    const ctx: PathSort = .{ .entries = common.values() };
    // std.log.warn("1. {} ({})", .{ common.keys()[0], common.values()[0] });
    // std.log.warn("2. {} ({})", .{ common.keys()[1], common.values()[1] });
    // std.log.warn("3. {} ({})", .{ common.keys()[2], common.values()[2] });
    // std.log.warn("4. {} ({})", .{ common.keys()[3], common.values()[3] });
    // std.log.warn("5. {} ({})", .{ common.keys()[4], common.values()[4] });
    common.sort(ctx);
    // std.log.warn("1. {} ({})", .{ common.keys()[0], common.values()[0] });
    // std.log.warn("2. {} ({})", .{ common.keys()[1], common.values()[1] });
    // std.log.warn("3. {} ({})", .{ common.keys()[2], common.values()[2] });
    // std.log.warn("4. {} ({})", .{ common.keys()[3], common.values()[3] });
    // std.log.warn("5. {} ({})", .{ common.keys()[4], common.values()[4] });
    for (0..10) |i| {
        std.log.warn("{}. {s} -> {s} ({})", .{ i, common.keys()[i].a, common.keys()[i].b, common.values()[i] });
    }

    // var rng: usize = 1;
    // var vis = std.StringHashMap(void).init(allocator);
    // var curr = double_graph.keys()[0];
    // var prev: []const u8 = "";
    // var i: usize = 0;
    // while (true) : (i += 1) {
    //     std.log.warn("{s}", .{curr});
    //     if (!vis.contains(curr)) {
    //         std.log.warn("NEW {}: {s} -> {s}", .{ i, prev, curr });
    //         try vis.put(curr, {});
    //     }
    //     const next = double_graph.get(curr).?;
    //     const idx = rng % next.items.len;
    //     rng = rng *% 17;
    //     prev = curr;
    //     curr = next.items[idx];
    // }

    // rem("bvb", "cmg", &graph);
    // rem("hfx", "pzl", &graph);
    // rem("nvd", "jqt", &graph);

    // std.log.warn("{}", .{graph.count()});
    // var iter = graph.keyIterator();
    // while (iter.next()) |k| {
    //     std.log.warn("  - {s}: {}", .{ k.*, graph.get(k.*).?.items.len });
    //     for (graph.get(k.*).?.items) |k2| {
    //         std.log.warn("    * {s}: {}", .{ k2, graph.get(k2).?.items.len });
    //     }
    // }

    // const Connection = struct { a: []const u8, b: []const u8 };
    // _ = Connection;

    // const keys = graph.keys();
    // const values = graph.values();
    // const max = double_graph.keys().len;

    // std.log.err("Max {} {}", .{ graph.keys().len, max });

    // for (keys, values, 0..) |a, bs, i| {
    //     std.log.warn("{}", .{i});
    //     for (bs.items) |b| {
    //         for (keys, values, 0..) |c, ds, j| {
    //             if (i == j) continue;
    //             for (ds.items) |d| {
    //                 for (keys, values, 0..) |e, fs, k| {
    //                     if (i == k or j == k) continue;
    //                     for (fs.items) |f| {
    //                         const count_a = try countWithLimit(allocator, a, b, c, d, e, f, max, double_graph) orelse continue;
    //                         if (count_a == max) continue;
    //                         // const count_b = try countWithLimit(allocator, d, e, f, a, b, c, max - count_a, double_graph) orelse continue;
    //                         // if (count_a == 0 or count_b == 0) continue;
    //                         std.log.err("FOUND {} for {s} {s} {s} {s} {s} {s}", .{ count_a, a, b, c, d, e, f });
    //                     }
    //                 }
    //             }
    //         }
    //     }
    // }

    // const count_a = try countWithLimit(allocator, "hfx", "bvb", "nvd", "pzl", "cmg", "jqt", max, double_graph);
    // std.log.warn("AAA {?}", .{count_a});
    // const count_b = try countWithLimit(allocator, "pzl", "hfx", "bvb", "nvd", max - count_a, double_graph);
    // if (count_a == 0 or count_b == 0) continx;
    // std.log.err("FOUND {} {?}", .{ count_a, count_b });

    // const a = try countWithoutLimit(allocator, "bvb", graph);
    // const b = try countWithLimit(allocator, "cmg", max - a, graph);
    // std.log.err("COUNT1 {}", .{a});
    // std.log.err("COUNT2 {?}", .{b});

    return 0;
}

fn rem(a: []const u8, b: []const u8, graph: *std.StringArrayHashMap(std.ArrayList([]const u8))) void {
    var a_ele = graph.getPtr(a).?;
    for (a_ele.items, 0..) |t, i| {
        if (!std.mem.eql(u8, t, b)) continue;
        _ = a_ele.swapRemove(i);
        break;
    }
    var b_ele = graph.getPtr(b).?;
    for (b_ele.items, 0..) |t, i| {
        if (!std.mem.eql(u8, t, a)) continue;
        _ = b_ele.swapRemove(i);
        break;
    }
}

fn countWithoutLimit(allocator: Allocator, start: []const u8, graph: std.StringArrayHashMap(std.ArrayList([]const u8))) !usize {
    var visited = std.StringHashMap(void).init(allocator);
    defer visited.deinit();

    var queue = std.ArrayList([]const u8).init(allocator);
    defer queue.deinit();
    try queue.append(start);

    while (queue.popOrNull()) |curr| {
        if (visited.contains(curr)) continue;
        try visited.put(curr, {});
        try queue.appendSlice((graph.get(curr) orelse continue).items);
    }

    return visited.count();
}
fn countWithLimit(allocator: Allocator, a: []const u8, b: []const u8, c: []const u8, d: []const u8, e: []const u8, f: []const u8, max_count: usize, graph: std.StringArrayHashMap(std.ArrayList([]const u8))) !?usize {
    var visited = std.StringHashMap(void).init(allocator);
    defer visited.deinit();

    var queue = std.ArrayList([]const u8).init(allocator);
    defer queue.deinit();
    try queue.append(a);

    while (queue.popOrNull()) |curr| {
        if (visited.contains(curr)) continue;
        // std.log.warn("curr {s}", .{curr});
        try visited.put(curr, {});
        if (visited.count() > max_count) return null;
        const next = (graph.get(curr) orelse continue).items;
        try queue.ensureUnusedCapacity(next.len);

        if (std.mem.eql(u8, curr, a)) {
            for (next) |n| {
                if (std.mem.eql(u8, n, d)) continue;
                // std.log.warn("  a next {s}", .{n});
                queue.appendAssumeCapacity(n);
            }
        } else if (std.mem.eql(u8, curr, b)) {
            for (next) |n| {
                if (std.mem.eql(u8, n, e)) continue;
                // std.log.warn("  b next {s}", .{n});
                queue.appendAssumeCapacity(n);
            }
        } else if (std.mem.eql(u8, curr, c)) {
            for (next) |n| {
                if (std.mem.eql(u8, n, f)) continue;
                // std.log.warn("  c next {s}", .{n});
                queue.appendAssumeCapacity(n);
            }
        } else if (std.mem.eql(u8, curr, d)) {
            for (next) |n| {
                if (std.mem.eql(u8, n, a)) continue;
                // std.log.warn("  c next {s}", .{n});
                queue.appendAssumeCapacity(n);
            }
        } else if (std.mem.eql(u8, curr, e)) {
            for (next) |n| {
                if (std.mem.eql(u8, n, b)) continue;
                // std.log.warn("  c next {s}", .{n});
                queue.appendAssumeCapacity(n);
            }
        } else if (std.mem.eql(u8, curr, f)) {
            for (next) |n| {
                if (std.mem.eql(u8, n, c)) continue;
                // std.log.warn("  c next {s}", .{n});
                queue.appendAssumeCapacity(n);
            }
        } else {
            for (next) |n| {
                // std.log.warn("  d next {s}", .{n});
                queue.appendAssumeCapacity(n);
            }
        }
    }

    return visited.count();
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
        pub fn hash(_: @This(), key: T) u32 {
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHashStrat(&hasher, key, .Deep);
            return @truncate(hasher.final());
        }
        pub fn eql(_: @This(), a: T, b: T, _: usize) bool {
            // return std.mem.eql(T, a, b);
            return std.mem.eql(u8, a.a, b.a) and std.mem.eql(u8, a.b, b.b);
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
