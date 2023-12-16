const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

pub const input = @embedFile("input.txt");
const example1 = @embedFile("example1.txt");

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
    try std.testing.expectEqual(@as(u64, 21), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 525152), try solve(.two, example1, std.testing.allocator));
}

const MemoKey = packed struct(u16) { record_idx: u8, group_idx: u8 };
const memo_map_size = std.math.maxInt(u16);

fn subsolve(record: []u8, groups: []const u32, record_idx: u8, group_idx: u8, memo: *[memo_map_size]u64) u64 {
    // Discard "."s
    var idx: usize = record_idx;
    while (idx < record.len and record[idx] == '.') {
        idx += 1;
    }

    if (idx >= record.len) {
        return if (group_idx == groups.len) 1 else 0;
    }

    const memo_key: MemoKey = .{ .record_idx = @intCast(idx), .group_idx = group_idx };
    const memo_val = memo[@as(u16, @bitCast(memo_key))];
    if (memo_val != std.math.maxInt(u64)) {
        return memo_val;
    }

    const group_target = record[idx]; // "?" or "#"
    if (group_target == '#') {
        if (group_idx == groups.len) {
            // No groups left
            return 0;
        }

        // Check if the group is possible
        const start_idx = idx;
        var size: usize = 1;
        idx += 1;
        while (size < groups[group_idx] and idx < record.len) : (idx += 1) {
            if (record[idx] == '.') break;
            size += 1;
        }

        if (size != groups[group_idx] or !(idx >= record.len or record[idx] == '.' or record[idx] == '?')) {
            // Impossible
            return 0;
        }

        // +1 is for the . / ? wich needs to follow
        const result = subsolve(record, groups, @intCast(start_idx + size + 1), group_idx + 1, memo);
        // Caching this seems to be hurting performace
        // memo[@as(u16, @bitCast(memo_key))] = result;
        return result;
    } else { // "?"
        var result: u64 = 0;

        record[idx] = '#';
        result += subsolve(record, groups, @intCast(idx), group_idx, memo);
        result += subsolve(record, groups, @intCast(idx + 1), group_idx, memo);
        record[idx] = '?';

        memo[@as(u16, @bitCast(memo_key))] = result;
        return result;
    }
}

var memo_map = [_]u64{undefined} ** memo_map_size;
pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    var result: u64 = 0;

    var groups = std.ArrayList(u32).init(allocator);
    defer groups.deinit();

    var line_iter = tokenizeSca(u8, in, '\n');
    var line_i: usize = 1;
    while (line_iter.next()) |line| : (line_i += 1) {
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

        const record = if (part == .one) try allocator.dupe(u8, record_text) else bloated_record_text.items;
        defer if (part == .one) allocator.free(record);
        const group_counts = if (part == .one) group_counts_text else bloated_group_text.items;

        var group_iter = splitSca(u8, group_counts, ',');
        while (group_iter.next()) |group| {
            try groups.append(try parseInt(u32, group, 10));
        }

        @memset(&memo_map, std.math.maxInt(u64));
        const permuts = subsolve(record, groups.items, 0, 0, &memo_map);
        result += permuts;

        groups.clearRetainingCapacity();
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
