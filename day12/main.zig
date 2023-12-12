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

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, &arena)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, &arena)});
}
test "Part 1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    try std.testing.expectEqual(@as(u64, 21), try solve(.one, example1, &arena));
    // try std.testing.expectEqual(@as(u64, 6), try solve(.one, example2, std.testing.allocator));
}
test "Part 2" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    try std.testing.expectEqual(@as(u64, 6), try solve(.two, example1, &arena));
}

const MemoCtx = struct {
    pub fn hash(_: MemoCtx, key: []const u32) u64 {
        var h: u64 = 0;
        for (key) |k| {
            h +%= std.hash.Wyhash.hash(h, std.mem.asBytes(&k));
        }
        return h;
        // std.log.warn("hash: {any} {}", .{ key, std.hash.Wyhash.hash(0, std.mem.asBytes(&key)) });
        // return std.hash.Wyhash.hash(0, std.mem.asBytes(&key));
    }
    pub fn eql(_: MemoCtx, a: []const u32, b: []const u32) bool {
        // std.log.warn("eql: {any} {any} {}", .{ a, b, std.meta.eql(a, b) });
        return std.meta.eql(a, b);
    }
};
const MemoMap = std.StringHashMap(std.HashMapUnmanaged([]const u32, []std.ArrayListUnmanaged(u32), MemoCtx, std.hash_map.default_max_load_percentage));

fn subsolve(in: []const u8, groups: []const u32, memo: *MemoMap, allocator: Allocator) !?[]std.ArrayListUnmanaged(u32) {
    // std.log.err("Subsolve: {s} {any}", .{ in, groups });
    // Discard "."s
    var idx: usize = 0;
    while (idx < in.len and in[idx] == '.') {
        idx += 1;
    }

    // if (memo.get(in[idx..])) |memo2| {
    //     // std.log.err("Key:", .{});
    //     // var kit = memo2.keyIterator();
    //     // while (kit.next()) |group| {
    //     //     std.log.err(" - {any}", .{group.*});
    //     // }
    //     // std.log.err("Value:", .{});
    //     // var vit = memo2.valueIterator();
    //     // while (vit.next()) |group| {
    //     //     std.log.err(" -", .{});
    //     //     for (group.*) |group2| {
    //     //         std.log.err(" ~ {any}", .{group2.items});
    //     //     }
    //     // }

    //     if (memo2.get(groups)) |possible| {
    //         // std.log.err("use cache {any} for {s}:", .{ groups, in[idx..] });
    //         // for (possible) |group| {
    //         //     std.log.err(" - {any}", .{group.items});
    //         // }
    //         // std.log.warn("use", .{});
    //         return possible;
    //     }
    // }

    if (idx == in.len) {
        // Empty string
        return &.{};
    }

    // std.log.warn("Discarded: {s}", .{in[idx..]});

    const group_target = in[idx]; // "?" or "#"
    if (group_target == '#') {
        if (groups.len == 0) {
            // No groups left
            // std.log.warn("No groups left", .{});
            return null;
        }

        // Check if the group is possible
        const start_idx = idx;
        var size: usize = 1;
        idx += 1;
        while (size < groups[0] and idx < in.len) : (idx += 1) {
            if (in[idx] == '.') break;
            size += 1;
        }

        if (size != groups[0]) {
            // Impossible
            // std.log.warn("Impossible {} {}", .{ size, groups[0] });
            return null;
        }

        // Check that the group can be terminated
        if (!(idx >= in.len or in[idx] == '.' or in[idx] == '?')) {
            // Impossible
            // std.log.warn("Impossible 2", .{});
            return null;
        }

        // Take first group and recurse
        // Includes bounding char if not OOB
        const extra_take: usize = if (start_idx + size == in.len) 0 else 1;
        var possible_groups = (try subsolve(in[start_idx + size + extra_take ..], groups[1..], memo, allocator)) orelse return null;
        // std.log.warn("Damaged: {} -> ", .{groups[0]});
        for (possible_groups) |*group| {
            try group.insert(allocator, 0, groups[0]);
            // std.log.warn("    {any}", .{group});
        }
        if (possible_groups.len == 0) {
            possible_groups = try allocator.alloc(std.ArrayListUnmanaged(u32), 1);
            possible_groups[0] = .{};
            try possible_groups[0].append(allocator, groups[0]);
        }
        return possible_groups;
    } else { // "?"
        // Generate all permutations for this block and check those
        const start_idx = idx;
        var group_size: usize = 0;
        while (idx < in.len and in[idx] == group_target) : (idx += 1) {
            group_size += 1;
        }

        const permuts = try std.math.powi(usize, 2, group_size);

        var possible_groups: std.ArrayListUnmanaged(std.ArrayListUnmanaged(u32)) = .{};

        var curr = try allocator.dupe(u8, in);
        defer allocator.free(curr);

        for (0..permuts) |permut| {
            for (0..group_size) |i| {
                const mask = @as(u32, 1) << @intCast(i);
                curr[start_idx + i] = if ((permut & mask) == 0) '#' else '.';
            }
            // std.log.warn("Permut: {} {s}", .{ permut, curr[start_idx..] });
            try possible_groups.appendSlice(allocator, (try subsolve(curr[start_idx..], groups, memo, allocator)) orelse continue);
        }

        if (possible_groups.items.len == 0) return &.{};

        const slice = try possible_groups.toOwnedSlice(allocator);

        // const key1 = try allocator.dupe(u8, in[start_idx..]);
        // const key2 = try allocator.dupe(u32, groups);

        // const gop = try memo.getOrPut(key1);
        // if (!gop.found_existing) {
        //     gop.value_ptr.* = .{};
        // }
        // const gop2 = try gop.value_ptr.getOrPut(allocator, key2);
        // if (!gop2.found_existing) {
        //     gop2.value_ptr.* = try allocator.dupe(std.ArrayListUnmanaged(u32), slice);
        //     // std.log.err("put cache: {any} for {s}:", .{ key2, key1 });
        //     // for (gop2.value_ptr.*) |group| {
        //     //     std.log.err(" - {any}", .{group.items});
        //     // }
        //     // std.log.warn("put", .{});
        // } else {
        //     unreachable;
        // }

        return slice;
    }
    unreachable;
}

pub fn solve(comptime part: Part, in: []const u8, arena: *std.heap.ArenaAllocator) !u64 {
    const allocator = arena.allocator();

    var result: u32 = 0;

    var groups = std.ArrayList(u32).init(arena.child_allocator);
    defer groups.deinit();

    var memo = MemoMap.init(arena.child_allocator);
    defer memo.deinit();

    var line_iter = tokenizeSca(u8, in, '\n');
    var line_i: usize = 0;
    while (line_iter.next()) |line| : (line_i += 1) {
        defer {
            memo.clearRetainingCapacity();
            groups.clearRetainingCapacity();
            _ = arena.reset(.retain_capacity);
        }

        std.log.err("{}/1000", .{line_i});

        var part_iter = splitSca(u8, line, ' ');
        const record_text = part_iter.next().?;
        const group_counts_text = part_iter.next().?;

        const bloat_fact = 5;
        var bloated_record_text = if (part == .two) try std.ArrayList(u8).initCapacity(allocator, line.len * bloat_fact + bloat_fact - 1) else {};
        defer if (part == .two) bloated_record_text.deinit();
        var bloated_group_text = if (part == .two) try std.ArrayList(u8).initCapacity(allocator, line.len * bloat_fact + bloat_fact - 1) else {};
        defer if (part == .two) bloated_group_text.deinit();
        if (part == .two) {
            for (0..bloat_fact) |i| {
                bloated_record_text.appendSliceAssumeCapacity(record_text);
                if (i != bloat_fact - 1)
                    bloated_record_text.appendAssumeCapacity('?');
                bloated_group_text.appendSliceAssumeCapacity(group_counts_text);
                if (i != bloat_fact - 1)
                    bloated_group_text.appendAssumeCapacity(',');
            }
        }

        const record = if (part == .one) record_text else bloated_record_text.items;
        const group_counts = if (part == .one) group_counts_text else bloated_group_text.items;
        // std.log.warn("{s} {s}", .{ record, group_counts });

        var group_iter = splitSca(u8, group_counts, ',');
        while (group_iter.next()) |group| {
            try groups.append(try parseInt(u32, group, 10));
        }

        const possible_groups = try subsolve(record, groups.items, &memo, allocator) orelse continue;
        std.log.err("Result:", .{});
        for (possible_groups) |*group| {
            std.log.err("    {any}", .{group.items});
            if (std.mem.eql(u32, group.items, groups.items)) {
                result += 1;
            }
        }

        // const n = std.mem.count(u8, record, "?");
        // const permuts = try std.math.powi(usize, 2, n);

        // var indices = try allocator.alloc(usize, n);
        // defer allocator.free(indices);
        // var idx: usize = 0;
        // for (record, 0..) |char, i| {
        //     if (char == '?') {
        //         indices[idx] = i;
        //         idx += 1;
        //     }
        // }

        // var current_permut = try allocator.alloc(u8, record.len);
        // defer allocator.free(current_permut);

        // @memcpy(current_permut, record);

        // var permuts_cnt: u32 = 0;

        // outer: for (0..permuts) |perm| {
        //     // std.log.err("next", .{});
        //     for (0..n) |i| {
        //         const mask = @as(u32, 1) << @intCast(i);
        //         current_permut[indices[i]] = if ((perm & mask) == 0) '#' else '.';
        //     }

        //     // std.log.warn("{s}", .{current_permut});

        //     var group_idx: usize = 0;
        //     var count: u32 = 0;
        //     for (current_permut) |char| {
        //         if (char == '#') {
        //             count += 1;
        //         } else if (char == '.' and count > 0) {
        //             if (group_idx >= groups.items.len) continue :outer;
        //             if (count != groups.items[group_idx]) continue :outer;
        //             count = 0;
        //             group_idx += 1;
        //         }
        //     }
        //     if (count > 0) {
        //         if (group_idx >= groups.items.len) continue :outer;
        //         if (count != groups.items[group_idx]) continue :outer;
        //         group_idx += 1;
        //     }
        //     // std.log.err("ij {}", .{group_idx});

        //     if (group_idx != groups.items.len) continue :outer;
        //     permuts_cnt += 1;
        //     // std.log.warn("{s}", .{current_permut});
        // }

        // // std.log.warn("{} {} {} {}", .{ n, permuts, permuts_cnt, groups.items.len });
        // result += permuts_cnt;
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

fn lcm_single(a: u64, b: u64) u64 {
    return a * b / std.math.gcd(a, b);
}
fn lcm(numbers: []const u64) u64 {
    return if (numbers.len > 2)
        lcm_single(numbers[0], lcm(numbers[1..]))
    else
        lcm_single(numbers[0], numbers[1]);
}
