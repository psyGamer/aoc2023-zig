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
    std.log.info("Result (Part 1): {}", .{try solve(.one, input)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u32, 8), try solve(.one, example1));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u32, 2286), try solve(.two, example2));
}

const Entry = struct {
    red: u32 = 0,
    green: u32 = 0,
    blue: u32 = 0,

    pub fn parse(in: []const u8) !Entry {
        var result: Entry = .{};

        var ele_iter = splitSca(u8, in, ',');
        while (ele_iter.next()) |ele| {
            var part_iter = splitSca(u8, trim(u8, ele, " "), ' ');
            const count = try parseInt(u32, part_iter.next().?, 10);
            const part_type = part_iter.next().?;
            if (eql(u8, part_type, "red")) {
                result.red = count;
            } else if (eql(u8, part_type, "green")) {
                result.green = count;
            } else if (eql(u8, part_type, "blue")) {
                result.blue = count;
            } else {
                std.log.err("Unknown part type: {s}", .{part_type});
                unreachable;
            }
        }

        return result;
    }
};

pub fn solve(comptime part: Part, in: []const u8) !u32 {
    var result: u32 = 0;

    var i: u32 = 1;
    var iter = tokenizeSca(u8, in, '\n');
    while (iter.next()) |line| : (i += 1) {
        // Get rid of the "Game xx: " prefix
        const col_idx = indexOf(u8, line, ':').?;
        const trimmed_line = line[(col_idx + 2)..];

        // Part 1
        const max_red = 12;
        const max_green = 13;
        const max_blue = 14;
        var all_possible = true;
        // Part 2
        var min_red: u32 = 0;
        var min_green: u32 = 0;
        var min_blue: u32 = 0;

        var entry_iter = splitSca(u8, trimmed_line, ';');
        while (entry_iter.next()) |entry_text| {
            const entry = try Entry.parse(trim(u8, entry_text, " "));
            if (part == .one and (entry.red > max_red or entry.green > max_green or entry.blue > max_blue)) {
                all_possible = false;
                break;
            } else if (part == .two) {
                min_red = @max(min_red, entry.red);
                min_green = @max(min_green, entry.green);
                min_blue = @max(min_blue, entry.blue);
            }
        }

        if (part == .one and all_possible) {
            result += i;
        } else if (part == .two) {
            result += min_red * min_green * min_blue;
        }
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
const eql = std.mem.eql;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;
