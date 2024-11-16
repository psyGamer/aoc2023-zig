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
    try std.testing.expectEqual(@as(u64, 1320), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 145), try solve(.two, example1, std.testing.allocator));
}

fn hash(str: []const u8) u8 {
    var sum: u32 = 0;
    for (str) |c| {
        if (c == '\n') continue;
        sum += c;
        sum *= 17;
        sum %= 256;
    }
    return @intCast(sum);
}

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    var result: u32 = 0;

    const BoxMap = std.ArrayHashMap([]const u8, u8, SliceCtx(u8), false);
    var boxes = [_]BoxMap{BoxMap.init(allocator)} ** 256;

    var comma_iter = tokenizeSca(u8, in, ',');
    while (comma_iter.next()) |line| {
        if (part == .one) {
            result += hash(line);
            continue;
        }

        var i: usize = 0;
        while (i < line.len) : (i += 1) {
            if (line[i] == '=' or line[i] == '-') break;
        }

        const box = hash(line[0..i]);
        if (line[i] == '=') {
            try boxes[box].put(line[0..i], line[i + 1]);
        } else {
            _ = boxes[box].orderedRemove(line[0..i]);
        }
    }

    if (part == .one) return result;

    for (&boxes, 1..) |*box, i| {
        for (box.keys(), 1..) |key, j| {
            result += @intCast(i * j * (box.get(key).? - '0'));
        }
        box.deinit();
    }

    return result;
}

fn SliceCtx(comptime T: type) type {
    return struct {
        pub fn hash(_: @This(), key: []const T) u32 {
            var hasher = std.hash.Wyhash.init(0);
            std.hash.autoHashStrat(&hasher, key, .Deep);
            return @truncate(hasher.final());
        }
        pub fn eql(_: @This(), a: []const T, b: []const T, _: usize) bool {
            return std.mem.eql(T, a, b);
        }
    };
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
