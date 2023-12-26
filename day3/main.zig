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

pub const std_options = struct {
    pub const log_level = .info;
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u32, 4361), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u32, 8), try solve(.two, example2, std.testing.allocator));
}

fn getAtPos(x: usize, y: usize, width: usize, buf: []const u8) u8 {
    return buf[y * width + x];
}
fn digitListToNumber(nums: std.ArrayList(u8)) u32 {
    var result: u32 = 0;
    for (nums.items) |num| {
        result *= 10;
        result += num - '0';
    }
    return result;
}
fn useMapValue(map: Array2D(i32), x: usize, y: usize) u32 {
    const value = map.get(x, y);

    // Remove values to the left
    var nx = x;
    while (nx > 0) {
        nx -= 1;
        if (map.get(nx, y) != value) break;
        map.set(nx, y, 0);
    }
    // Remove values to the right
    nx = x;
    while (nx < map.width - 1) {
        nx += 1;
        if (map.get(nx, y) != value) break;
        map.set(nx, y, 0);
    }

    return @max(0, value);
}

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u32 {
    var result: u32 = 0;
    const width = indexOf(u8, in, '\n').? + 1;
    const height = in.len / width;

    var map = try Array2D(i32).initWithDefault(allocator, width - 1, height, 0);
    defer map.deinit(allocator);
    const symbol_value = -1; // Magic value for symbols

    // Generate lookup map
    var nums = std.ArrayList(u8).init(allocator);
    defer nums.deinit();
    for (0..map.height) |y| {
        for (0..width) |x| {
            const char = getAtPos(x, y, width, in);
            if (std.ascii.isDigit(char)) {
                try nums.append(char);
            } else {
                if (char != '.' and char != '\n') {
                    map.set(x, y, symbol_value);
                }

                const value = digitListToNumber(nums);
                var nx = x;
                while (nx > 0 and nx > x -| nums.items.len) {
                    nx -= 1;
                    map.set(nx, y, @intCast(value));
                }
                nums.clearRetainingCapacity();
            }
        }
    }

    for (0..map.height) |y| {
        for (0..map.width) |x| {
            const value = map.get(x, y);
            if (value >= 0) continue;

            const left_edge = x == 0;
            const top_edge = y == 0;
            const right_edge = x == map.width - 1;
            const bottom_edge = y == map.height - 1;

            if (part == .one) {
                // Above
                if (!top_edge) {
                    if (!left_edge) result += useMapValue(map, x - 1, y - 1);
                    result += useMapValue(map, x, y - 1);
                    if (!right_edge) result += useMapValue(map, x + 1, y - 1);
                }
                // Below
                if (!bottom_edge) {
                    if (!left_edge) result += useMapValue(map, x - 1, y + 1);
                    result += useMapValue(map, x, y + 1);
                    if (!right_edge) result += useMapValue(map, x + 1, y + 1);
                }
                // Center
                if (!left_edge) result += useMapValue(map, x - 1, y);
                if (!right_edge) result += useMapValue(map, x + 1, y);
            } else if (part == .two) {
                var numbers = std.ArrayList(u32).init(allocator);
                defer numbers.deinit();
                // Above
                if (!top_edge) {
                    if (!left_edge) try numbers.append(useMapValue(map, x - 1, y - 1));
                    try numbers.append(useMapValue(map, x, y - 1));
                    if (!right_edge) try numbers.append(useMapValue(map, x + 1, y - 1));
                }
                // Below
                if (!bottom_edge) {
                    if (!left_edge) try numbers.append(useMapValue(map, x - 1, y + 1));
                    try numbers.append(useMapValue(map, x, y + 1));
                    if (!right_edge) try numbers.append(useMapValue(map, x + 1, y + 1));
                }
                // Center
                if (!left_edge) try numbers.append(useMapValue(map, x - 1, y));
                if (!right_edge) try numbers.append(useMapValue(map, x + 1, y));

                var val: u32 = 1;
                var next_to: usize = 0;
                for (numbers.items) |num| {
                    if (num != 0) {
                        next_to += 1;
                        val *= num;
                    }
                }

                if (next_to == 2) result += val;
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
