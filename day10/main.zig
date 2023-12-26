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
const example4 = @embedFile("example4.txt");
const example5 = @embedFile("example5.txt");

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
    try std.testing.expectEqual(@as(u64, 4), try solve(.one, example1, std.testing.allocator));
    // try std.testing.expectEqual(@as(u64, 8), try solve(.one, example2, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 4), try solve(.two, example3, std.testing.allocator));
    try std.testing.expectEqual(@as(u64, 8), try solve(.two, example4, std.testing.allocator));
    try std.testing.expectEqual(@as(u64, 10), try solve(.two, example5, std.testing.allocator));
}

const Vec2u = struct {
    x: usize,
    y: usize,
};
const PipeTile = enum(u8) {
    none = '.',
    h = '-',
    v = '|',
    ne = 'L',
    nw = 'J',
    sw = '7',
    se = 'F',
    animal = 'S',
};
const Direction = enum { up, down, left, right };

fn advancePosition(map: Array2D(PipeTile), position: *Vec2u, prev_dir: *Direction) void {
    switch (map.get(position.x, position.y)) {
        .h => {
            if (prev_dir.* == .left) {
                position.x += 1;
            } else {
                position.x -= 1;
            }
        },
        .v => {
            if (prev_dir.* == .up) {
                position.y += 1;
            } else {
                position.y -= 1;
            }
        },
        .ne => {
            if (prev_dir.* == .up) {
                position.x += 1;
                prev_dir.* = .left;
            } else {
                position.y -= 1;
                prev_dir.* = .down;
            }
        },
        .nw => {
            if (prev_dir.* == .up) {
                position.x -= 1;
                prev_dir.* = .right;
            } else {
                position.y -= 1;
                prev_dir.* = .down;
            }
        },
        .se => {
            if (prev_dir.* == .down) {
                position.x += 1;
                prev_dir.* = .left;
            } else {
                position.y += 1;
                prev_dir.* = .up;
            }
        },
        .sw => {
            if (prev_dir.* == .down) {
                position.x -= 1;
                prev_dir.* = .right;
            } else {
                position.y += 1;
                prev_dir.* = .up;
            }
        },
        else => unreachable,
    }
}
fn getAtPos(x: usize, y: usize, width: usize, buf: []const u8) u8 {
    return buf[y * width + x];
}
pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    const width = indexOf(u8, in, '\n').? + 1;
    const height = in.len / width;

    var map = try Array2D(PipeTile).init(allocator, width - 1, height);
    defer map.deinit(allocator);

    var animal_pos: Vec2u = .{ .x = 4, .y = 0 };

    for (0..map.height) |y| {
        for (0..map.width) |x| {
            var tile: PipeTile = @enumFromInt(getAtPos(x, y, width, in));
            if (tile == .animal) {
                animal_pos = .{ .x = x, .y = y };
                // Lets just assume the animal is never on the edge
                const t_tile: PipeTile = @enumFromInt(getAtPos(x, y - 1, width, in));
                const b_tile: PipeTile = @enumFromInt(getAtPos(x, y + 1, width, in));
                const l_tile: PipeTile = @enumFromInt(getAtPos(x - 1, y, width, in));
                const r_tile: PipeTile = @enumFromInt(getAtPos(x + 1, y, width, in));
                const t = t_tile == .v or t_tile == .sw or t_tile == .se;
                const b = b_tile == .v or b_tile == .nw or b_tile == .ne;
                const l = l_tile == .h or l_tile == .ne or l_tile == .se;
                const r = r_tile == .h or r_tile == .nw or r_tile == .sw;

                // Find correct tile
                tile = if (t and b)
                    .v
                else if (l and r)
                    .h
                else if (t and r)
                    .ne
                else if (t and l)
                    .nw
                else if (b and r)
                    .se
                else if (b and l)
                    .sw
                else
                    unreachable;
            }
            map.set(x, y, tile);
        }
    }

    var visited = try Array2D(bool).initWithDefault(allocator, map.width, map.height, false);
    defer visited.deinit(allocator);

    var d: u32 = 0;
    var forward = animal_pos;
    var backward = animal_pos;
    // Determine first positions
    var forward_prev_dir: Direction = undefined;
    var backward_prev_dir: Direction = undefined;
    switch (map.get(animal_pos.x, animal_pos.y)) {
        .h => {
            forward_prev_dir = .left;
            backward_prev_dir = .right;
        },
        .v => {
            forward_prev_dir = .up;
            backward_prev_dir = .down;
        },
        .ne => {
            forward_prev_dir = .up;
            backward_prev_dir = .right;
        },
        .nw => {
            forward_prev_dir = .up;
            backward_prev_dir = .left;
        },
        .se => {
            forward_prev_dir = .down;
            backward_prev_dir = .right;
        },
        .sw => {
            forward_prev_dir = .down;
            backward_prev_dir = .left;
        },
        else => unreachable,
    }

    while (true) {
        // Check if the two ends reached eachother
        if (visited.get(forward.x, forward.y) or visited.get(backward.x, backward.y)) break;
        visited.set(forward.x, forward.y, true);
        visited.set(backward.x, backward.y, true);
        advancePosition(map, &forward, &forward_prev_dir);
        advancePosition(map, &backward, &backward_prev_dir);
        d += 1;
    }

    if (part == .one) {
        return d - 1;
    }

    // Part 2
    // Perform a raycast, to determine if a point is inside/outside
    var edge_counts = try Array2D(u32).initWithDefault(allocator, map.width, map.height, 420);
    defer edge_counts.deinit(allocator);

    for (0..map.height) |y| {
        var edges: u32 = 0;
        var last_edge: PipeTile = .none;
        for (0..map.width) |x| {
            const tile = map.get(x, y);
            if (tile == .none or visited.get(x, y) == false) {
                edge_counts.set(x, y, edges);
                continue;
            }

            switch (last_edge) {
                .h => {
                    if (tile == .h) continue;
                },
                .ne => {
                    if (tile == .sw or tile == .nw) last_edge = tile;
                    if (tile == .nw) edges += 1;
                },
                .se => {
                    if (tile == .sw or tile == .nw) last_edge = tile;
                    if (tile == .sw) edges += 1;
                },
                else => {
                    edges += 1;
                    last_edge = tile;
                },
            }
        }
    }

    var inside: u32 = 0;
    for (0..map.height) |y| {
        for (0..map.width) |x| {
            if ((map.get(x, y) == .none or visited.get(x, y) == false) and edge_counts.get(x, y) % 2 == 1)
                inside += 1;
        }
    }

    return inside;
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
