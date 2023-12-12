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

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u64, 2), try solve(.one, example1, std.testing.allocator));
    // try std.testing.expectEqual(@as(u64, 6), try solve(.one, example2, std.testing.allocator));
}
test "Part 2" {
    // try std.testing.expectEqual(@as(u64, 6), try solve(.two, example3, std.testing.allocator));
}

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    _ = part;
    var result: u32 = 0;

    var groups = std.ArrayList(u32).init(allocator);
    defer groups.deinit();

    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| {
        defer groups.clearRetainingCapacity();

        var part_iter = splitSca(u8, line, ' ');
        const record = part_iter.next().?;
        const group_counts = part_iter.next().?;
        var group_iter = splitSca(u8, group_counts, ',');
        while (group_iter.next()) |group| {
            try groups.append(try parseInt(u32, group, 10));
        }

        const n = std.mem.count(u8, record, "?");
        const permuts = try std.math.powi(usize, 2, n);

        var indices = try allocator.alloc(usize, n);
        defer allocator.free(indices);
        var idx: usize = 0;
        for (record, 0..) |char, i| {
            if (char == '?') {
                indices[idx] = i;
                idx += 1;
            }
        }

        var current_permut = try allocator.alloc(u8, record.len);
        defer allocator.free(current_permut);

        @memcpy(current_permut, record);

        var permuts_cnt: u32 = 0;

        outer: for (0..permuts) |perm| {
            // std.log.err("next", .{});
            for (0..n) |i| {
                const mask = @as(u32, 1) << @intCast(i);
                current_permut[indices[i]] = if ((perm & mask) == 0) '#' else '.';
            }

            // std.log.warn("{s}", .{current_permut});

            var group_idx: usize = 0;
            var count: u32 = 0;
            for (current_permut) |char| {
                if (char == '#') {
                    count += 1;
                } else if (char == '.' and count > 0) {
                    if (group_idx >= groups.items.len) continue :outer;
                    if (count != groups.items[group_idx]) continue :outer;
                    count = 0;
                    group_idx += 1;
                }
            }
            if (count > 0) {
                if (group_idx >= groups.items.len) continue :outer;
                if (count != groups.items[group_idx]) continue :outer;
                group_idx += 1;
            }
            // std.log.err("ij {}", .{group_idx});

            if (group_idx != groups.items.len) continue :outer;
            permuts_cnt += 1;
            // std.log.warn("{s}", .{current_permut});
        }

        // std.log.warn("{} {} {} {}", .{ n, permuts, permuts_cnt, groups.items.len });
        result += permuts_cnt;
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
