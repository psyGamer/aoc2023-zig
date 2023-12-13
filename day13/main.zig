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
    try std.testing.expectEqual(@as(u64, 700), try solve(.one, example2, std.testing.allocator));
}
test "Part 2" {
    // try std.testing.expectEqual(@as(u64, 6), try solve(.two, example3, std.testing.allocator));
}

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    _ = part;
    var result: u32 = 0;

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var v_reflect: ?[]bool = null;

    var line_iter = splitSca(u8, in, '\n');
    while (line_iter.next()) |line| {
        if (line.len > 0) {
            if (v_reflect == null) {
                v_reflect = try allocator.alloc(bool, line.len - 1);
                @memset(v_reflect.?, true);
            }
            try lines.append(line);

            std.debug.assert(line.len % 2 == 1);

            // Check for reflectivness
            for (1..line.len) |i| {
                if (!v_reflect.?[i - 1]) continue;

                var left: usize = i - 1;
                var right: usize = i;
                while (true) {
                    if (line[left] != line[right]) {
                        v_reflect.?[i - 1] = false;
                        break;
                    }

                    if (left <= 0 or right >= line.len - 1) break;
                    left -= 1;
                    right += 1;
                }
            }

            continue;
        }

        std.debug.assert(lines.items.len % 2 == 1);

        // Check for V reflectivity
        if (indexOf(bool, v_reflect.?, true)) |idx| {
            result += @intCast(idx + 1);
        }
        // Check for H reflectivity
        var h_reflect = try allocator.alloc(bool, lines.items.len - 1);
        defer allocator.free(h_reflect);
        @memset(h_reflect, true);

        // const offset = if (lines.items.len % 2 == 0) 1 else 0;
        for (0..v_reflect.?.len + 1) |x| {
            for (1..lines.items.len) |i| {
                if (!h_reflect[i - 1]) continue;

                var top: usize = i - 1;
                var bottom: usize = i;
                while (true) {
                    if (lines.items[top][x] != lines.items[bottom][x]) {
                        h_reflect[i - 1] = false;
                        break;
                    }

                    if (top <= 0 or bottom >= lines.items.len - 1) break;
                    top -= 1;
                    bottom += 1;
                }
            }
        }

        if (indexOf(bool, h_reflect, true)) |idx| {
            result += @intCast(100 * (idx + 1));
        }

        lines.clearRetainingCapacity();
        allocator.free(v_reflect.?);
        v_reflect = null;
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
