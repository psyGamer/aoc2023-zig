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
    try std.testing.expectEqual(@as(u64, 2), try solve(.one, example1, std.testing.allocator));
    try std.testing.expectEqual(@as(u64, 6), try solve(.one, example2, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 6), try solve(.two, example3, std.testing.allocator));
}

fn toNodeID(in: []const u8) NodeID {
    return in[2] | @as(u16, in[1]) << 8 | @as(u24, in[0]) << 16;
    // return .{ .one = in[0], .two = in[1], .three = in[2] };
}

const NodeID = u24;
const Node = struct {
    left: NodeID,
    right: NodeID,
};

fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    var line_iter = tokenizeSca(u8, in, '\n');

    const route = line_iter.next().?;

    var nodes = std.AutoHashMap(NodeID, Node).init(allocator);
    defer nodes.deinit();

    var start_nodes = std.ArrayList(NodeID).init(allocator);
    defer start_nodes.deinit();

    while (line_iter.next()) |line| {
        // Luckily, the letters are always at the same offsets
        const id = toNodeID(line[0..3]);
        const node: Node = .{
            .left = toNodeID(line[7..10]),
            .right = toNodeID(line[12..15]),
        };
        try nodes.put(id, node);

        if (part == .two and line[2] == 'A') try start_nodes.append(id);
    }

    if (part == .one) {
        const start_id = toNodeID("AAA");
        const end_id = toNodeID("ZZZ");

        var current_id: NodeID = start_id;
        var steps: u32 = 0;
        var i: usize = 0;
        while (current_id != end_id) : ({
            i = (i + 1) % route.len;
            steps += 1;
        }) {
            if (route[i] == 'L') {
                current_id = nodes.get(current_id).?.left;
            } else {
                current_id = nodes.get(current_id).?.right;
            }
        }

        return steps;
    } else if (part == .two) {
        // Re-use the start nodes
        var current_ids = start_nodes.items;
        var steps: u32 = 0;
        var i: usize = 0;

        var loop_offsets = try allocator.alloc(?usize, current_ids.len);
        defer allocator.free(loop_offsets);
        @memset(loop_offsets, null);
        var remaining_offsets = current_ids.len;

        outer: while (true) : ({
            i = (i + 1) % route.len;
            steps += 1;
        }) {
            var done = true;
            for (current_ids, 0..) |id, j| {
                if (id & 0xFF != 'Z') {
                    done = false;
                } else {
                    if (loop_offsets[j] == null) loop_offsets[j] = steps;
                    remaining_offsets -= 1;
                    if (remaining_offsets == 0) break :outer;
                }

                if (route[i] == 'L') {
                    current_ids[j] = nodes.get(id).?.left;
                } else {
                    current_ids[j] = nodes.get(id).?.right;
                }
            }
            if (done) break;
        }

        const lcm_input = try allocator.alloc(u64, loop_offsets.len);
        defer allocator.free(lcm_input);
        for (loop_offsets, lcm_input) |off, *lcm_in| {
            lcm_in.* = @intCast(off.?);
        }

        // All ghost have looped at least once
        // The least-common-multiple is the result
        return lcm(lcm_input);
    }
    unreachable;
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
