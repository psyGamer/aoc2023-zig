const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const input = @embedFile("input.txt");
const example1 = @embedFile("example1.txt");
const example2 = @embedFile("example2.txt");

const Part = enum { one, two };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u64, 114), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u64, 6), try solve(.two, example2, std.testing.allocator));
}

fn solve(part: Part, in: []const u8, allocator: Allocator) !u64 {
    _ = part;

    var line_iter = tokenizeSca(u8, in, '\n');

    var sequences = std.ArrayList(std.ArrayList(i32)).init(allocator);
    defer sequences.deinit();

    try sequences.resize(2); // Required for inital list and first subset
    @memset(sequences.items, std.ArrayList(i32).init(allocator));

    var result: i32 = 0;

    while (line_iter.next()) |line| {
        var seq_iter = splitSca(u8, line, ' ');
        while (seq_iter.next()) |seq| {
            try sequences.items[0].append(try parseInt(i32, seq, 10));
        }

        // Propegate down
        var i: usize = 0;
        while (true) : (i += 1) {
            var all_zero = true;
            for (0..(sequences.items[i].items.len - 1)) |j| {
                const value = (sequences.items[i].items[j + 1] - sequences.items[i].items[j]);
                // If ever value is 0 except the first one, there won't be any differences when further propagating down
                if (value != 0) all_zero = false;
                try sequences.items[i + 1].append(@intCast(value));
            }
            if (all_zero) break;
            try sequences.append(std.ArrayList(i32).init(allocator));
        }
        i += 1;
        // Append zero
        try sequences.items[i].append(0);
        // Propegate up
        while (i > 0) : (i -= 1) {
            const last = sequences.items[i].items.len;
            const new = sequences.items[i - 1].items[last - 1] + sequences.items[i].items[last - 1];
            try sequences.items[i - 1].append(new);
        }
        result += sequences.items[0].items[sequences.items[0].items.len - 1];

        for (sequences.items) |*seq| {
            seq.clearRetainingCapacity();
        }
    }

    for (sequences.items) |*seq| {
        seq.deinit();
    }

    return @intCast(result);
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
