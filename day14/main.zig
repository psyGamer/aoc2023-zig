const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

pub const input = @embedFile("input.txt");
const example1 = @embedFile("example1.txt");
const example2 = @embedFile("example2.txt");

const Array2D = @import("array2d.zig").Array2D;
const Part = enum { one, two };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u64, 136), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    // try std.testing.expectEqual(@as(u64, 6), try solve(.two, example3, std.testing.allocator));
}

const State = enum(u8) { none = '.', cube = '#', round = 'O' };

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    _ = part;
    const width = indexOf(u8, in, '\n').?;
    const height = in.len / width - 1;

    var map = try Array2D(State).initWithDefault(allocator, width, height, .none);
    defer map.deinit(allocator);

    {
        var y: usize = 0;
        var line_iter = tokenizeSca(u8, in, '\n');
        while (line_iter.next()) |line| : (y += 1) {
            for (line, 0..) |char, x| {
                map.set(x, y, @enumFromInt(char));
            }
        }
    }

    // Move all round rocks north until they hit a cube or OOB
    for (1..height) |y| {
        for (0..width) |x| {
            if (map.get(x, y) != .round) continue;

            var ny = y;
            while (true) {
                ny -= 1;
                if (map.get(x, ny) != .none) {
                    ny += 1;
                    break;
                }
                if (ny == 0) break;
            }

            map.set(x, y, .none);
            map.set(x, ny, .round);
        }
    }

    // Calculate weight
    var result: u32 = 0;
    for (0..height) |y| {
        for (0..width) |x| {
            if (map.get(x, y) == .round) {
                result += @intCast(height - y);
            }
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
