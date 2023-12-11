const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const input = @embedFile("input.txt");
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
    try std.testing.expectEqual(@as(u64, 374), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 82000210), try solve(.two, example1, std.testing.allocator));
}

const Vec2u = struct { x: usize, y: usize };
const Vec2ux2 = struct { a: Vec2u, b: Vec2u };

fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    const width = indexOf(u8, in, '\n').?;
    const height = in.len / width;

    var col_with_galaxy = try allocator.alloc(bool, width);
    defer allocator.free(col_with_galaxy);
    var row_with_galaxy = try allocator.alloc(bool, height - 1);
    defer allocator.free(row_with_galaxy);

    var galaxies = std.ArrayList(Vec2u).init(allocator);
    defer galaxies.deinit();

    @memset(col_with_galaxy, false);
    @memset(row_with_galaxy, false);

    var y: usize = 0;
    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| : (y += 1) {
        for (line, 0..) |char, x| {
            if (char == '#') {
                col_with_galaxy[x] = true;
                row_with_galaxy[y] = true;
                try galaxies.append(.{ .x = x, .y = y });
            }
        }
    }

    var pairs = std.AutoArrayHashMap(Vec2ux2, void).init(allocator);
    defer pairs.deinit();

    for (galaxies.items, 0..) |a, i| {
        for (galaxies.items, 0..) |b, j| {
            if (i == j) continue;
            try pairs.put(.{ .a = if (i < j) a else b, .b = if (i < j) b else a }, {});
        }
    }

    var sum: usize = 0;

    for (pairs.keys()) |pair| {
        const start_x = if (pair.a.x > pair.b.x) pair.b.x else pair.a.x;
        const end_x = if (pair.a.x > pair.b.x) pair.a.x else pair.b.x;
        const start_y = if (pair.a.y > pair.b.y) pair.b.y else pair.a.y;
        const end_y = if (pair.a.y > pair.b.y) pair.a.y else pair.b.y;
        const x_expansion = std.mem.count(bool, col_with_galaxy[start_x..end_x], &.{false}) * (@as(usize, (if (part == .two) 1000000 else 2) - 1));
        const y_expansion = std.mem.count(bool, row_with_galaxy[start_y..end_y], &.{false}) * (@as(usize, (if (part == .two) 1000000 else 2) - 1));

        sum += @abs(@as(i64, @intCast(pair.a.x)) - @as(i64, @intCast(pair.b.x))) + @as(u64, @intCast(x_expansion -| 0));
        sum += @abs(@as(i64, @intCast(pair.a.y)) - @as(i64, @intCast(pair.b.y))) + @as(u64, @intCast(y_expansion -| 0));
    }

    return sum;
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
