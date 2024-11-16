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
    try std.testing.expectEqual(@as(u32, 6440), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u32, 5905), try solve(.two, example2, std.testing.allocator));
}

const Card = enum(u8) {
    two = '2',
    three = '3',
    four = '4',
    five = '5',
    six = '6',
    seven = '7',
    eight = '8',
    nine = '9',
    ten = 'T',
    joker = 'J',
    queen = 'Q',
    king = 'K',
    ass = 'A',

    pub fn toValue(card: Card, part: Part) u8 {
        if (part == .one) {
            return switch (card) {
                .two => 2,
                .three => 3,
                .four => 4,
                .five => 5,
                .six => 6,
                .seven => 7,
                .eight => 8,
                .nine => 9,
                .ten => 10,
                .joker => 11,
                .queen => 12,
                .king => 13,
                .ass => 14,
            };
        } else if (part == .two) {
            return switch (card) {
                .joker => 1,
                .two => 2,
                .three => 3,
                .four => 4,
                .five => 5,
                .six => 6,
                .seven => 7,
                .eight => 8,
                .nine => 9,
                .ten => 10,
                .queen => 11,
                .king => 12,
                .ass => 13,
            };
        }
        unreachable;
    }
};
const HandType = enum {
    high_card,
    one_pair,
    two_pair,
    three_of_a_kind,
    full_house,
    four_of_a_kind,
    five_of_a_kind,

    pub fn parse(in: []const u8, comptime part: Part) HandType {
        var cards = [_]Card{undefined} ** 5;
        var counts = [_]u32{0} ** 5;
        var idx: usize = 0;

        for (0..5) |i| {
            const card: Card = @enumFromInt(in[i]);

            var found = false;
            for (0..idx) |j| {
                if (counts[j] > 0) {
                    if (cards[j] == card) {
                        counts[j] += 1;
                        found = true;
                        break;
                    }
                }
            }

            if (!found) {
                cards[idx] = card;
                counts[idx] = 1;
                idx += 1;
            }
        }

        // Promote jokers
        if (part == .two) {
            for (0..5) |i| {
                if (counts[i] == 0 or cards[i] != .joker) continue;

                var best: u32 = 0;
                var best_idx: usize = std.math.maxInt(usize);
                for (counts[0..], 0..) |item, j| {
                    if (cards[j] != .joker and best < item) {
                        best = item;
                        best_idx = j;
                    }
                }
                if (best_idx == std.math.maxInt(usize)) break;

                counts[best_idx] += counts[i];

                // Copy rest over
                for (i..@min(4, idx)) |j| {
                    counts[j] = counts[j + 1];
                    cards[j] = cards[j + 1];
                }
                // Reset last
                counts[4] = 0;

                idx -= 1;
                break;
            }
        }

        return if (idx == 1)
            .five_of_a_kind
        else if (idx == 2 and (counts[0] == 4 or counts[1] == 4))
            .four_of_a_kind
        else if (idx == 2 and (counts[0] == 3 or counts[1] == 3))
            .full_house
        else if (idx == 3 and (counts[0] == 3 or counts[1] == 3 or counts[2] == 3))
            .three_of_a_kind
        else if (idx == 3 and (counts[0] == 2 or counts[1] == 2 or counts[2] == 2))
            .two_pair
        else if (idx == 4)
            .one_pair
        else
            .high_card;
    }
};
const Hand = struct {
    type: HandType,
    cards: [5]Card,
    bid: u32,
    part: Part,

    pub fn parse(in: []const u8, bid: u32, comptime part: Part) Hand {
        return .{
            .type = HandType.parse(in, part),
            .cards = .{
                @enumFromInt(in[0]),
                @enumFromInt(in[1]),
                @enumFromInt(in[2]),
                @enumFromInt(in[3]),
                @enumFromInt(in[4]),
            },
            .bid = bid,
            .part = part,
        };
    }

    pub fn lessThan(_: void, lhs: Hand, rhs: Hand) bool {
        if (lhs.type != rhs.type) return @intFromEnum(lhs.type) < @intFromEnum(rhs.type);
        for (0..5) |i| {
            if (lhs.cards[i] != rhs.cards[i]) return lhs.cards[i].toValue(lhs.part) < rhs.cards[i].toValue(rhs.part);
        }
        return false;
    }
};

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u32 {
    var hands = std.ArrayList(Hand).init(allocator);
    defer hands.deinit();

    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| {
        var ele_iter = splitSca(u8, line, ' ');
        try hands.append(Hand.parse(ele_iter.next().?, try parseInt(u32, ele_iter.next().?, 10), part));
    }

    sort(Hand, hands.items, {}, Hand.lessThan);

    var result: u32 = 0;
    for (hands.items, 1..) |hand, i| {
        result += hand.bid * @as(u32, @intCast(i));
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
