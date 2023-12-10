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
    try std.testing.expectEqual(@as(i32, 114), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(i32, 2), try solve(.two, example2, std.testing.allocator));
}

fn lagrange_interpolation(values: []const i32, x: i32) f64 {
    var result: f64 = 0;

    var i: i32 = 0;
    while (i < values.len) : (i += 1) {
        var term: f64 = @floatFromInt(values[@intCast(i)]);
        var j: i32 = 0;
        while (j < values.len) : (j += 1) {
            if (i == j) continue;
            term = term * @as(f64, @floatFromInt(x - j)) / @as(f64, @floatFromInt(i - j));
        }
        result += term;
    }

    return result;
}

fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !i32 {
    var result: i32 = 0;

    var sequence = std.ArrayList(i32).init(allocator);
    defer sequence.deinit();

    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| {
        var seq_iter = splitSca(u8, line, ' ');
        while (seq_iter.next()) |seq| {
            try sequence.append(try parseInt(i32, seq, 10));
        }

        if (part == .one) {
            result += @intFromFloat(@round(lagrange_interpolation(sequence.items, @intCast(sequence.items.len))));
        } else if (part == .two) {
            result += @intFromFloat(@round(lagrange_interpolation(sequence.items, -1)));
        }

        sequence.clearRetainingCapacity();
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
