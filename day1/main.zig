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
    std.log.info("Result (Part 1): {}", .{solve(.one, input)});
    std.log.info("Result (Part 2): {}", .{solve(.two, input)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u32, 142), solve(.one, example1));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u32, 281), solve(.two, example2));
}

pub fn solve(comptime part: Part, in: []const u8) u32 {
    var result: u32 = 0;
    var iter = tokenizeSca(u8, in, '\n');
    while (iter.next()) |line| {
        var first: u8 = std.math.maxInt(u8);
        var last: u8 = std.math.maxInt(u8);

        var i: usize = 0;
        while (i < line.len) {
            const number = b: {
                if (part == .one) {
                    const val = line[i] - '0';
                    i += 1;
                    break :b val;
                } else if (part == .two) {
                    if (isSpelledNumber(line[i..])) |spelled| {
                        i += spelled.advance - 1;
                        break :b spelled.number;
                    }
                    const val = line[i] - '0';
                    i += 1;
                    break :b val;
                }
                unreachable;
            };

            // number >= 1 is implicitly true
            if (number <= 9) {
                if (first == std.math.maxInt(u8)) {
                    first = number;
                }
                last = number;
            }
        }
        result += first * 10 + last;
    }

    return result;
}

const SpelledResult = struct { number: u8, advance: u8 };
fn isSpelledNumber(string: []const u8) ?SpelledResult {
    return if (std.mem.indexOf(u8, string, "one") == 0)
        .{ .number = 1, .advance = 3 }
    else if (std.mem.indexOf(u8, string, "two") == 0)
        .{ .number = 2, .advance = 3 }
    else if (std.mem.indexOf(u8, string, "three") == 0)
        .{ .number = 3, .advance = 5 }
    else if (std.mem.indexOf(u8, string, "four") == 0)
        .{ .number = 4, .advance = 4 }
    else if (std.mem.indexOf(u8, string, "five") == 0)
        .{ .number = 5, .advance = 4 }
    else if (std.mem.indexOf(u8, string, "six") == 0)
        .{ .number = 6, .advance = 3 }
    else if (std.mem.indexOf(u8, string, "seven") == 0)
        .{ .number = 7, .advance = 5 }
    else if (std.mem.indexOf(u8, string, "eight") == 0)
        .{ .number = 8, .advance = 5 }
    else if (std.mem.indexOf(u8, string, "nine") == 0)
        .{ .number = 9, .advance = 4 }
    else
        null;
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
