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

fn solve(part: Part, in: []const u8, allocator: Allocator) !u32 {
    var result: u32 = 0;
    _ = part;
    const width = indexOf(u8, in, '\n').? + 1;
    const height = in.len / width;

    var nums = std.ArrayList(u8).init(allocator);
    defer nums.deinit();

    for (0..height) |y| {
        nums.clearRetainingCapacity();

        main_loop: for (0..width) |x| {
            const char = getAtPos(x, y, width, in);
            if (std.ascii.isDigit(char)) {
                try nums.append(char);
            } else if (nums.items.len > 0) {
                if (char != '.' and char != '\n') {
                    result += digitListToNumber(nums);
                    nums.clearRetainingCapacity();
                    continue :main_loop;
                } else {
                    // Above
                    const start_x = @max(0, x -| nums.items.len -| 1);
                    const end_x = @min(width - 1, x + 1);
                    if (y >= 1) {
                        for (start_x..end_x) |nx| {
                            if (getAtPos(nx, y - 1, width, in) != '.') {
                                result += digitListToNumber(nums);
                                nums.clearRetainingCapacity();
                                continue :main_loop;
                            }
                        }
                    }
                    // Below
                    if (y < height - 1) {
                        for (start_x..end_x) |nx| {
                            if (getAtPos(nx, y + 1, width, in) != '.') {
                                result += digitListToNumber(nums);
                                nums.clearRetainingCapacity();
                                continue :main_loop;
                            }
                        }
                    }
                    // Left
                    if (x > nums.items.len) {
                        if (getAtPos(start_x, y, width, in) != '.') {
                            result += digitListToNumber(nums);
                            nums.clearRetainingCapacity();
                            continue :main_loop;
                        }
                    }
                }
                // Not valid
                nums.clearRetainingCapacity();
            }
        }
    }

    return result;
}

test "Part 1" {
    try std.testing.expectEqual(@as(u32, 4361), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u32, 8), try solve(.two, example2, std.testing.allocator));
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
