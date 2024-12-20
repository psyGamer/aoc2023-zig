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

pub const std_options: std.Options = .{
    .log_level = .info,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u32, 13), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u32, 30), try solve(.two, example2, std.testing.allocator));
}

const Card = struct { index: usize, winning: u32 };

fn resolveCardsAdded(cards: []const Card, memo: *std.AutoHashMap(usize, u32), card: Card) !u32 {
    if (memo.get(card.index)) |result| {
        return result;
    }

    var count: u32 = card.winning;
    for (1..(card.winning + 1)) |i| {
        count += try resolveCardsAdded(cards, memo, cards[card.index + i]);
    }

    try memo.put(card.index, count);
    return count;
}

pub fn solve(part: Part, in: []const u8, allocator: Allocator) !u32 {
    var result: u32 = 0;

    // Everything is formatting in a nice grid.
    const start1_idx = indexOf(u8, in, ':').? + 2; // Skip the ": "
    const start2_idx = indexOf(u8, in, '|').? + 2; // Skip the "| "
    const end1_idx = start2_idx - 3; // Move back the " | "
    const end2_idx = indexOf(u8, in, '\n').?;

    var winning = std.ArrayList(u32).init(allocator);
    defer winning.deinit();
    var having = std.ArrayList(u32).init(allocator);
    defer having.deinit();

    var cards = std.ArrayList(Card).init(allocator);
    defer cards.deinit();

    var line_iter = tokenizeSca(u8, in, '\n');
    var idx: usize = 0;
    while (line_iter.next()) |line| : (idx += 1) {
        // Winning
        var i: usize = start1_idx;
        // Each number is 2 digits
        while (i + 2 <= end1_idx) : (i += 3) {
            try winning.append(try parseInt(u8, trim(u8, line[i..(i + 2)], " "), 10));
        }
        // Having
        i = start2_idx;
        // Each number is 2 digits
        while (i + 2 <= end2_idx) : (i += 3) {
            try having.append(try parseInt(u8, trim(u8, line[i..(i + 2)], " "), 10));
        }

        var winning_count: u32 = 0;
        for (having.items) |have| {
            if (contains(u32, winning.items, have)) winning_count += 1;
        }

        if (part == .one and winning_count > 0) {
            result += try std.math.powi(u32, 2, @intCast(winning_count - 1));
        } else if (part == .two) {
            try cards.append(.{ .index = idx, .winning = winning_count });
        }

        winning.clearRetainingCapacity();
        having.clearRetainingCapacity();
    }

    if (part == .two) {
        var memo = std.AutoHashMap(usize, u32).init(allocator);
        defer memo.deinit();

        var additional: u32 = 0;
        for (cards.items) |card| {
            additional += try resolveCardsAdded(cards.items, &memo, card);
        }
        return @as(u32, @intCast(cards.items.len)) + additional;
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

fn contains(comptime T: type, buffer: []const T, target: T) bool {
    for (buffer) |element| {
        if (element == target) return true;
    }
    return false;
}
