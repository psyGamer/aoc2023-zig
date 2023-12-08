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
    try std.testing.expectEqual(@as(u32, 13), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u32, 8), try solve(.two, example2, std.testing.allocator));
}

fn solve(part: Part, in: []const u8, allocator: Allocator) !u32 {
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

    var winning_counts = std.ArrayList(u32).init(allocator);
    _ = winning_counts;

    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| {
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

        var winning_count: usize = 0;
        for (having.items) |have| {
            if (contains(u32, winning.items, have)) winning_count += 1;
        }

        if (winning_count > 0) {
            result += try std.math.powi(u32, 2, @intCast(winning_count - 1));
        }

        winning.clearRetainingCapacity();
        having.clearRetainingCapacity();
    }
    _ = part;
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
