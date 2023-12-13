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

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u64, 405), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 400), try solve(.two, example1, std.testing.allocator));
}

fn solve_h_reflect(line: []const u8, memo: []bool) void {
    for (1..line.len) |i| {
        if (!memo[i - 1]) continue;

        var left: usize = i - 1;
        var right: usize = i;
        while (true) {
            if (line[left] != line[right]) {
                memo[i - 1] = false;
                break;
            }

            if (left <= 0 or right >= line.len - 1) break;
            left -= 1;
            right += 1;
        }
    }
}
fn solve_v_reflect(lines: [][]const u8, x: usize, memo: []bool) void {
    for (1..lines.len) |i| {
        if (!memo[i - 1]) continue;

        var top: usize = i - 1;
        var bottom: usize = i;
        while (true) {
            if (lines[top][x] != lines[bottom][x]) {
                memo[i - 1] = false;
                break;
            }

            if (top <= 0 or bottom >= lines.len - 1) break;
            top -= 1;
            bottom += 1;
        }
    }
}

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    var result: u32 = 0;

    var lines = std.ArrayList([]u8).init(allocator);
    defer lines.deinit();

    var line_iter = splitSca(u8, in, '\n');
    outer: while (line_iter.next()) |line| {
        if (line.len > 0) {
            try lines.append(try allocator.dupe(u8, line));
            continue;
        }

        defer {
            for (lines.items) |l| {
                allocator.free(l);
            }
            lines.clearRetainingCapacity();
        }

        var h_point: u32 = 0;
        var v_point: u32 = 0;

        // Check for V reflectivity
        var h_reflect = try allocator.alloc(bool, lines.items[0].len - 1);
        defer allocator.free(h_reflect);
        @memset(h_reflect, true);

        for (lines.items) |l| {
            solve_h_reflect(l, h_reflect);
        }

        if (indexOf(bool, h_reflect, true)) |idx| {
            h_point = @intCast(idx + 1);
        }

        // Check for H reflectivity
        var v_reflect = try allocator.alloc(bool, lines.items.len - 1);
        defer allocator.free(v_reflect);
        @memset(v_reflect, true);

        for (0..lines.items[0].len) |x| {
            solve_v_reflect(lines.items, x, v_reflect);
        }

        if (indexOf(bool, v_reflect, true)) |idx| {
            v_point = @intCast(idx + 1);
        }

        if (part == .one) {
            result += h_point + v_point * 100;
            continue;
        }

        for (0..lines.items.len) |ny| {
            for (0..lines.items[0].len) |nx| {
                const prev = lines.items[ny][nx];
                lines.items[ny][nx] = if (prev == '.') '#' else '.';

                // Check for V reflectivity
                @memset(h_reflect, true);

                for (lines.items) |l| {
                    solve_h_reflect(l, h_reflect);
                }

                var h_idx: ?usize = null;
                for (0..h_reflect.len) |i| {
                    if (i + 1 == h_point) continue;
                    if (h_reflect[i] == true) {
                        h_idx = i;
                        break;
                    }
                }

                if (h_idx) |idx| {
                    result += @intCast(idx + 1);
                    continue :outer;
                }

                // Check for H reflectivity
                @memset(v_reflect, true);

                for (0..lines.items[0].len) |x| {
                    solve_v_reflect(lines.items, x, v_reflect);
                }

                var v_idx: ?usize = null;
                for (0..v_reflect.len) |i| {
                    if (i + 1 == v_point) continue;
                    if (v_reflect[i] == true) {
                        v_idx = i;
                        break;
                    }
                }

                if (v_idx) |idx| {
                    result += @intCast(100 * (idx + 1));
                    continue :outer;
                }

                lines.items[ny][nx] = prev;
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
