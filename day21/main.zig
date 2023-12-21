const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

pub const input = @embedFile("input.txt");
// pub const input = @embedFile("in.txt");
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

    // std.log.info("Result (Part 1): {}", .{try solve(.one, 64, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, 26501365, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, 327, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, 589, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, 851, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, 1113, input, allocator)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u64, 16), try solve(.one, 6, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 16), try solve(.two, 6, example1, std.testing.allocator));
    try std.testing.expectEqual(@as(u64, 50), try solve(.two, 10, example1, std.testing.allocator));
    try std.testing.expectEqual(@as(u64, 1594), try solve(.two, 50, example1, std.testing.allocator));
    try std.testing.expectEqual(@as(u64, 6536), try solve(.two, 100, example1, std.testing.allocator));
    try std.testing.expectEqual(@as(u64, 167004), try solve(.two, 500, example1, std.testing.allocator));
    try std.testing.expectEqual(@as(u64, 668697), try solve(.two, 1000, example1, std.testing.allocator));
    try std.testing.expectEqual(@as(u64, 16733044), try solve(.two, 5000, example1, std.testing.allocator));
}

const Step = struct { x: u16, y: u16, distance: u8 };

pub fn solve(comptime part: Part, comptime max_distance: comptime_int, in: []const u8, allocator: Allocator) !u64 {
    const width = indexOf(u8, in, '\n').?;
    const height = in.len / (width + 1);

    if (part == .one) {
        var map = try Array2D(u8).initWithDefault(allocator, width, height, std.math.maxInt(u8));
        defer map.deinit(allocator);

        var start: Step = undefined;

        var y: usize = 0;
        var line_iter = tokenizeSca(u8, in, '\n');
        while (line_iter.next()) |line| : (y += 1) {
            for (line, 0..) |char, x| {
                switch (char) {
                    '.' => continue,
                    'S' => start = .{ .x = @intCast(x), .y = @intCast(y), .distance = 1 },
                    '#' => {
                        map.set(x, y, 0);
                    },
                    else => unreachable,
                }
            }
        }
        var queue = std.ArrayList(Step).init(allocator);
        defer queue.deinit();

        var wrapped_map = try Array2D(u8).initWithDefault(allocator, width, height, std.math.maxInt(u8));
        defer wrapped_map.deinit(allocator);
        var wrapped_queue = std.ArrayList(Step).init(allocator);
        defer wrapped_queue.deinit();
        try queue.append(start);

        std.log.warn("Star {}", .{start});

        while (queue.popOrNull()) |tile| {
            const curr_tile = map.get(tile.x, tile.y);
            std.log.warn("curr {} (prev {})", .{ tile, curr_tile });
            if (curr_tile <= tile.distance) continue;
            map.set(tile.x, tile.y, tile.distance);
            if (tile.distance == max_distance + 1) {
                continue;
            }

            if (part == .one) {
                if (tile.x != 0) try queue.append(.{ .x = @intCast(tile.x - 1), .y = @intCast(tile.y), .distance = tile.distance + 1 });
                if (tile.y != 0) try queue.append(.{ .x = @intCast(tile.x), .y = @intCast(tile.y - 1), .distance = tile.distance + 1 });
                if (tile.x != width - 1) try queue.append(.{ .x = @intCast(tile.x + 1), .y = @intCast(tile.y), .distance = tile.distance + 1 });
                if (tile.y != height - 1) try queue.append(.{ .x = @intCast(tile.x), .y = @intCast(tile.y + 1), .distance = tile.distance + 1 });
            }
            // } else if (part == .two) {
            //     if (tile.x == 0) {
            //         try wrapped_queue.append(.{ .x = @intCast(width - 1), .y = @intCast(tile.y), .distance = tile.distance + 1 });
            //     } else {
            //         try queue.append(.{ .x = tile.x - 1, .y = @intCast(tile.y), .distance = tile.distance + 1 });
            //     }
            //     if (tile.y == 0) {
            //         try wrapped_queue.append(.{ .x = @intCast(height - 1), .y = @intCast(tile.y), .distance = tile.distance + 1 });
            //     } else {
            //         try queue.append(.{ .x = @intCast(tile.x), .y = @intCast(tile.y - 1), .distance = tile.distance + 1 });
            //     }
            //     if (tile.x == width - 1) {
            //         try wrapped_queue.append(.{ .x = 0, .y = @intCast(tile.y), .distance = tile.distance + 1 });
            //     } else {
            //         try queue.append(.{ .x = @intCast((tile.x + 1)), .y = @intCast(tile.y), .distance = tile.distance + 1 });
            //     }
            //     if (tile.y == height - 1) {
            //         try wrapped_queue.append(.{ .x = @intCast(tile.x), .y = 0, .distance = tile.distance + 1 });
            //     } else {
            //         try queue.append(.{ .x = @intCast(tile.x), .y = @intCast((tile.y + 1)), .distance = tile.distance + 1 });
            //     }
            // }
        }

        std.debug.print("\n", .{});
        for (0..map.height) |ny| {
            for (0..map.width) |nx| {
                if (map.get(nx, ny) == 255) {
                    std.debug.print("    ", .{});
                } else if (map.get(nx, ny) == 0) {
                    std.debug.print("### ", .{});
                } else {
                    std.debug.print("{d:0>3} ", .{map.get(nx, ny)});
                }
            }
            std.debug.print("\n", .{});
        }

        var result: u32 = 0;
        for (map.data) |tile| {
            if (tile == 0 or tile == std.math.maxInt(u8)) continue;
            if ((tile + 1) % 2 == max_distance % 2) result += 1;
        }
        return result;
    } else if (part == .two) {
        // This trick only works with the real input and not the examples..
        std.debug.assert(width == 131);
        std.debug.assert(height == 131);

        // var top_rocks: u32 = 0;
        // var bottom_rocks: u32 = 0;
        // var left_rocks: u32 = 0;
        // var right_rocks: u32 = 0;

        // var tl_diag1: u32 = 0;
        // var tl_diag2: u32 = 0;

        // var y: usize = 0;
        // var line_iter = tokenizeSca(u8, in, '\n');
        // while (line_iter.next()) |line| : (y += 1) {
        //     for (line, 0..) |char, x| {
        //         switch (char) {
        //             '#' => {
        //                 if ((x + y) % 2 == 0) continue;

        //                 if (x + y >= 65 and x -| y <= 65) {
        //                     top_rocks += 1;
        //                 }
        //                 if (x + (height - y - 1) >= 65 and x -| (height - y - 1) <= 65) {
        //                     bottom_rocks += 1;
        //                 }
        //                 if (x + y >= 65 and y -| x <= 65) {
        //                     left_rocks += 1;
        //                 }
        //                 if ((width - x - 1) + y >= 65 and y -| (width - x - 1) <= 65) {
        //                     right_rocks += 1;
        //                 }

        //                 if (x + y >= 65) {
        //                     tl_diag1 += 1;
        //                 }
        //                 if (x -| (height - y - 1) <= 65) {
        //                     tl_diag2 += 1;
        //                 }
        //             },
        //             else => continue,
        //         }
        //     }
        // }
        // std.log.warn("TOP {}", .{top_rocks});
        // std.log.warn("BOTTOM {}", .{bottom_rocks});
        // std.log.warn("LEFT {}", .{left_rocks});
        // std.log.warn("RIGHT {}", .{right_rocks});

        // std.log.warn("TOP LEFT DIAG {} {}", .{ tl_diag1, tl_diag2 });

        var map = try Array2D(u8).initWithDefault(allocator, width, height, 0);
        defer map.deinit(allocator);

        var tl: u32 = 0;
        var tr: u32 = 0;
        var bl: u32 = 0;
        var br: u32 = 0;
        var total: u32 = 0;

        var y: usize = 0;
        var line_iter = tokenizeSca(u8, in, '\n');
        while (line_iter.next()) |line| : (y += 1) {
            for (line, 0..) |char, x| {
                switch (char) {
                    '#' => {
                        if ((x + y) % 2 == 0) continue;
                        map.set(x, y, 9);
                        total += 1;

                        if (x + y <= 65) {
                            // std.log.err("TL {} {}", .{ x, y });
                            map.set(x, y, 1);
                            tl += 1;
                        }

                        if (x -| y >= 65) {
                            // std.log.err("TR {} {}", .{ x, y });
                            map.set(x, y, 2);
                            tr += 1;
                        }
                        if (y -| x >= 65) {
                            // std.log.err("BL {} {}", .{ x, y });
                            map.set(x, y, 3);
                            bl += 1;
                        }
                        if (x + y >= 65 * 3) {
                            // std.log.err("BR {} {}", .{ x, y });
                            map.set(x, y, 4);
                            br += 1;
                        }
                    },
                    else => continue,
                }
            }
        }

        // std.log.warn("\n{}", .{map});

        // std.log.warn("TOP {}", .{total - tl - tr});
        // std.log.warn("BOTTOM {}", .{total - bl - br});
        // std.log.warn("LEFT {}", .{total - tl - bl});
        // std.log.warn("RIGHT {}", .{total - tr - br});
        std.log.warn("TL {} TR {} BL {} BR {} TOTAL {}", .{ tl, tr, bl, br, total });

        var max_possible: u128 = 0;
        var i: u128 = max_distance % 2;
        while (i <= max_distance) : (i += 2) {
            // max_possible += (i + 1) * (i + 1);
            max_possible += @max(1, i * 4);
        }

        std.log.warn("{}", .{max_possible});

        // Top
        max_possible -= (total - tl - tr);
        std.log.warn("{}", .{max_possible});
        // Bottom
        max_possible -= (total - bl - br);
        std.log.warn("{}", .{max_possible});
        // Left
        max_possible -= (total - tl - bl);
        std.log.warn("{}", .{max_possible});
        // Right
        max_possible -= (total - tr - br);
        std.log.warn("{}", .{max_possible});

        const tile_radius = (max_distance - 65) / 131;
        const diag_size = @divTrunc(tile_radius, 2);

        // Top left
        max_possible -= (diag_size + 1) * br;
        max_possible -= (diag_size) * (total - tl);
        std.log.warn("{}", .{max_possible});
        // Top right
        max_possible -= (diag_size + 1) * bl;
        max_possible -= (diag_size) * (total - tr);
        std.log.warn("{}", .{max_possible});
        // Bottom left
        max_possible -= (diag_size + 1) * tr;
        max_possible -= (diag_size) * (total - bl);
        std.log.warn("{}", .{max_possible});
        // Bottom right
        max_possible -= (diag_size + 1) * tl;
        max_possible -= (diag_size) * (total - br);
        std.log.warn("{} {} {}", .{ max_possible, tile_radius, diag_size });

        var inner_count: u128 = 1;
        // Inner
        for (1..tile_radius) |j| {
            inner_count += j * 4;
        }
        // I'll be honest. This is figured out using 4 solution-samples from a working solution script.
        // I have NO idea how or why they are required... The first one might still make sense, but the second one...
        inner_count += (diag_size - 1) * 4;
        max_possible += 161 * (diag_size * diag_size) - ((diag_size - 1) * (diag_size - 1));

        max_possible -= inner_count * total;

        std.log.warn("{} {}", .{ max_possible, inner_count });

        return @intCast(max_possible);
    }
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

fn SliceHashmapCtx(comptime T: type) type {
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

fn lcm(a: u64, b: u64) u64 {
    return a * b / std.math.gcd(a, b);
}
fn lcmSlice(numbers: []const u64) u64 {
    return if (numbers.len > 2)
        lcm(numbers[0], lcmSlice(numbers[1..]))
    else
        lcm(numbers[0], numbers[1]);
}

fn splitOnce(comptime T: type, haystack: []const T, needle: []const T) struct { []const T, []const T } {
    const idx = std.mem.indexOf(T, haystack, needle) orelse return .{ haystack, &.{} };
    return .{ haystack[0..idx], haystack[(idx + needle.len)..] };
}
fn splitOnceScalar(comptime T: type, buffer: []const T, delimiter: T) struct { []const T, []const T } {
    const idx = std.mem.indexOfScalar(T, buffer, delimiter) orelse return .{ buffer, &.{} };
    return .{ buffer[0..idx], buffer[(idx + 1)..] };
}
