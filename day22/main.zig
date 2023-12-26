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
const Array3D = @import("array3d.zig").Array3D;
const Part = enum { one, two };

pub const std_options = struct {
    pub const log_level = .info;
};

pub fn main() !void {
    for (0..1) |_| {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
        std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
    }
}
test "Part 1" {
    try std.testing.expectEqual(@as(u64, 5), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 7), try solve(.two, example1, std.testing.allocator));
}

const Vec3u = struct { x: u16, y: u16, z: u16 };
const Vec3i = struct { x: i16, y: i16, z: i16 };

const Brick = struct {
    a: Vec3u,
    b: Vec3u,

    supports: std.AutoArrayHashMap(*Brick, void),
    supported_by: std.AutoArrayHashMap(*Brick, void),

    pub fn lessThan(_: void, lhs: Brick, rhs: Brick) bool {
        return lhs.a.z < rhs.a.z;
    }

    pub fn format(value: Brick, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{},{},{}~{},{},{}", .{ value.a.x, value.a.y, value.a.z, value.b.x, value.b.y, value.b.z });
    }
};

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    var bricks = std.ArrayList(Brick).init(allocator);
    defer {
        for (bricks.items) |*b| {
            b.supports.deinit();
            b.supported_by.deinit();
        }
        bricks.deinit();
    }

    var max_width: usize = 0;
    var max_height: usize = 0;
    var min_width: usize = std.math.maxInt(usize);
    var min_height: usize = std.math.maxInt(usize);

    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| {
        var tilde_iter = splitSca(u8, line, '~');

        var comma_iter = splitSca(u8, tilde_iter.next().?, ',');
        const a: Vec3u = .{
            .x = try parseInt(u16, comma_iter.next().?, 10),
            .y = try parseInt(u16, comma_iter.next().?, 10),
            .z = try parseInt(u16, comma_iter.next().?, 10),
        };
        max_width = @max(max_width, a.x + 1);
        max_height = @max(max_height, a.y + 1);
        min_width = @min(min_width, a.x);
        min_height = @min(min_height, a.y);

        comma_iter = splitSca(u8, tilde_iter.next().?, ',');
        const b: Vec3u = .{
            .x = try parseInt(u16, comma_iter.next().?, 10),
            .y = try parseInt(u16, comma_iter.next().?, 10),
            .z = try parseInt(u16, comma_iter.next().?, 10),
        };
        max_width = @max(max_width, b.x + 1);
        max_height = @max(max_height, b.y + 1);
        min_width = @min(min_width, b.x);
        min_height = @min(min_height, b.y);

        try bricks.append(.{ .a = a, .b = b, .supports = std.AutoArrayHashMap(*Brick, void).init(allocator), .supported_by = std.AutoArrayHashMap(*Brick, void).init(allocator) });
    }

    // Sort bricks from bottom to top
    sort(Brick, bricks.items, {}, Brick.lessThan);

    var height_map = try Array2D(?*Brick).initWithDefault(allocator, max_width - min_width, max_height - min_height, null);
    defer height_map.deinit(allocator);

    var supported_by = std.AutoArrayHashMap(*Brick, void).init(allocator);
    defer supported_by.deinit();

    for (bricks.items) |*b| {
        // Slight assumptions made about the input
        std.debug.assert(b.a.x <= b.b.x);
        std.debug.assert(b.a.y <= b.b.y);
        std.debug.assert(b.a.z <= b.b.z);

        var max_ground_height: u16 = 0;
        supported_by.clearRetainingCapacity();

        if (b.a.x != b.b.x) { // +X
            for ((b.a.x - min_width)..(b.b.x - min_width + 1)) |x| {
                if (height_map.get(x, b.a.y - min_height)) |support| {
                    if (support.b.z > max_ground_height) {
                        max_ground_height = support.b.z;
                        supported_by.clearRetainingCapacity();
                        try supported_by.put(support, {});
                    } else if (support.b.z == max_ground_height) {
                        try supported_by.put(support, {});
                    }
                    continue;
                }
                max_ground_height = @max(max_ground_height, 0);
            }
        } else if (b.a.y != b.b.y) { // +Y
            for ((b.a.y - min_height)..(b.b.y - min_height + 1)) |y| {
                if (height_map.get(b.a.x - min_width, y)) |support| {
                    if (support.b.z > max_ground_height) {
                        max_ground_height = support.b.z;
                        supported_by.clearRetainingCapacity();
                        try supported_by.put(support, {});
                    } else if (support.b.z == max_ground_height) {
                        try supported_by.put(support, {});
                    }
                    continue;
                }
                max_ground_height = @max(max_ground_height, 0);
            }
        } else { // +Z / Single block
            if (height_map.get(b.a.x - min_width, b.a.y - min_height)) |support| {
                if (support.b.z > max_ground_height) {
                    max_ground_height = support.b.z;
                    supported_by.clearRetainingCapacity();
                    try supported_by.put(support, {});
                } else if (support.b.z == max_ground_height) {
                    try supported_by.put(support, {});
                }
            }
        }

        max_ground_height += 1; // Place on top of ground, not inside

        b.b.z -= b.a.z - max_ground_height;
        b.a.z = max_ground_height;
        b.supported_by = try supported_by.clone();

        // Update height map
        if (b.a.x != b.b.x) { // +X
            for ((b.a.x - min_width)..(b.b.x - min_width + 1)) |x| {
                height_map.set(x, b.a.y - min_height, b);
            }
        } else if (b.a.y != b.b.y) { // +Y
            for ((b.a.y - min_height)..(b.b.y - min_height + 1)) |y| {
                height_map.set(b.a.x - min_width, y, b);
            }
        } else { // +Z / Single block
            height_map.set(b.a.x - min_width, b.a.y - min_height, b);
        }
    }

    // Generate supports set
    for (bricks.items) |*b| {
        for (b.supported_by.keys()) |s| {
            try s.supports.put(b, {});
        }
    }

    var result: u32 = 0;

    if (part == .one) {
        for (bricks.items) |b| {
            var all_ok = true;
            for (b.supports.keys()) |s| {
                if (s.supported_by.keys().len <= 1) {
                    all_ok = false;
                }
            }
            if (all_ok) result += 1;
        }
    } else if (part == .two) {
        var seen = std.AutoHashMap(*Brick, void).init(allocator);
        defer seen.deinit();

        var queue = std.ArrayList(*Brick).init(allocator);
        defer queue.deinit();

        for (bricks.items) |*brick| {
            // Do a best-first-seach
            seen.clearRetainingCapacity();
            queue.clearRetainingCapacity();

            try queue.append(brick);

            while (queue.popOrNull()) |b| {
                try seen.put(b, {});
                for (b.supports.keys()) |child| {
                    var all_seen = true;
                    for (child.supported_by.keys()) |parent| {
                        if (!seen.contains(parent)) {
                            all_seen = false;
                            break;
                        }
                    }
                    if (all_seen) {
                        try queue.append(child);
                    }
                }
            }

            result += seen.count() - 1;
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

const scan = @import("scan.zig").scan;

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
