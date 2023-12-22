const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

pub const input = @embedFile("input.txt");
const example1 = @embedFile("example1.txt");
const example2 = @embedFile("example2.txt");

const Array3D = @import("array3d.zig").Array3D;
const Part = enum { one, two };

pub const std_options = struct {
    pub const log_level = .info;
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
    std.log.info("Result (Part 1): {}", .{try solve(.one, example2, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u64, 2), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    // try std.testing.expectEqual(@as(u64, 6), try solve(.two, example2, std.testing.allocator));
}

const Vec3u = struct { x: u16, y: u16, z: u16 };
const Vec3i = struct { x: i16, y: i16, z: i16 };
const Brick = struct { a: Vec3u, b: Vec3u };

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    _ = part;

    var bricks = std.ArrayList(Brick).init(allocator);
    defer bricks.deinit();

    var max_width: usize = 0;
    var max_height: usize = 0;
    var max_depth: usize = 0;

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
        max_depth = @max(max_depth, a.z + 1);

        comma_iter = splitSca(u8, tilde_iter.next().?, ',');
        const b: Vec3u = .{
            .x = try parseInt(u16, comma_iter.next().?, 10),
            .y = try parseInt(u16, comma_iter.next().?, 10),
            .z = try parseInt(u16, comma_iter.next().?, 10),
        };
        max_width = @max(max_width, b.x + 1);
        max_height = @max(max_height, b.y + 1);
        max_depth = @max(max_depth, b.z + 1);

        try bricks.append(.{ .a = a, .b = b });

        // std.log.warn("{} {}", .{ a, b });
    }

    var map = try Array3D(?*Brick).initWithDefault(allocator, max_width, max_height, max_depth, null);
    defer map.deinit(allocator);

    for (bricks.items) |*b| {
        const dir: Vec3i = .{
            .x = if (b.a.x == b.b.x) 0 else if (b.a.x < b.b.x) 1 else -1,
            .y = if (b.a.y == b.b.y) 0 else if (b.a.y < b.b.y) 1 else -1,
            .z = if (b.a.z == b.b.z) 0 else if (b.a.z < b.b.z) 1 else -1,
        };
        var curr: Vec3i = .{
            .x = @intCast(b.a.x),
            .y = @intCast(b.a.y),
            .z = @intCast(b.a.z),
        };

        while (true) : ({
            curr.x += dir.x;
            curr.y += dir.y;
            curr.z += dir.z;
        }) {
            // std.log.err("Setting {} at {}", .{ b, curr });
            map.set(@intCast(curr.x), @intCast(curr.y), @intCast(curr.z), b);
            if (curr.x == b.b.x and curr.y == b.b.y and curr.z == b.b.z) break;
        }
    }

    var supported_by_map = std.AutoArrayHashMap(*Brick, std.AutoArrayHashMap(*Brick, void)).init(allocator);

    while (true) {
        var all_supported = true;
        for (bricks.items) |*b| {
            const gop = try supported_by_map.getOrPut(b);
            if (!gop.found_existing) {
                gop.value_ptr.* = std.AutoArrayHashMap(*Brick, void).init(allocator);
            }
            var supported_by = gop.value_ptr;
            supported_by.clearRetainingCapacity();

            const dir: Vec3i = .{
                .x = if (b.a.x == b.b.x) 0 else if (b.a.x < b.b.x) 1 else -1,
                .y = if (b.a.y == b.b.y) 0 else if (b.a.y < b.b.y) 1 else -1,
                .z = if (b.a.z == b.b.z) 0 else if (b.a.z < b.b.z) 1 else -1,
            };
            // std.log.warn("dir {}: {}", .{ b.*, dir });

            if (dir.z != 0) {
                if (map.get(b.a.x, b.a.y, b.a.z - 1)) |s| {
                    // std.log.err("{} found support Y {}", .{ b.*, s });
                    try supported_by.put(s, {});
                }
            } else {
                var curr: Vec3i = .{
                    .x = @intCast(b.a.x),
                    .y = @intCast(b.a.y),
                    .z = @intCast(b.a.z),
                };

                while (true) : ({
                    curr.x += dir.x;
                    curr.y += dir.y;
                }) {
                    if (map.get(@intCast(curr.x), @intCast(curr.y), @intCast(curr.z - 1))) |s| {
                        // std.log.err("{} found support {} at {} {} {}", .{ b.*, s, curr.x, curr.y, curr.z - 1 });
                        try supported_by.put(s, {});
                    }
                    if (curr.x == b.b.x and curr.y == b.b.y) break;
                }
            }

            if (b.a.z == 1) {
                // std.log.err("On groud {}", .{b.*});
            } else if (supported_by.keys().len == 0) {
                // std.log.err("Not supported {}", .{b.*});
                all_supported = false;

                var curr: Vec3i = .{
                    .x = @intCast(b.a.x),
                    .y = @intCast(b.a.y),
                    .z = @intCast(b.a.z),
                };

                while (true) : ({
                    curr.x += dir.x;
                    curr.y += dir.y;
                    curr.z += dir.z;
                }) {
                    // std.log.err("Moving from {} {} {} to {} {} {}", .{ curr.x, curr.y, curr.z, curr.x, curr.y, curr.z - 1 });

                    map.set(@intCast(curr.x), @intCast(curr.y), @intCast(curr.z), null);
                    map.set(@intCast(curr.x), @intCast(curr.y), @intCast(curr.z - 1), b);
                    if (curr.x == b.b.x and curr.y == b.b.y and curr.z == b.b.z) break;
                }

                b.a.z -= 1;
                b.b.z -= 1;
            } else {
                // std.log.err("Supported {}", .{b.*});
            }
        }
        if (all_supported) break;
    }

    var supports = std.AutoArrayHashMap(*Brick, std.ArrayList(*Brick)).init(allocator);
    defer supports.deinit();

    for (bricks.items) |*b| {
        // const gop = try supports.getOrPut(b);
        // if (!gop.found_existing) {
        //     gop.value_ptr.* = std.ArrayList(Brick).init(allocator);
        // }
        for (supported_by_map.get(b).?.keys()) |s| {
            const gop2 = try supports.getOrPut(s);
            if (!gop2.found_existing) {
                gop2.value_ptr.* = std.ArrayList(*Brick).init(allocator);
            }
            try gop2.value_ptr.append(b);
        }
        // std.log.warn("{} SUP {any}", .{ b, supported_by_map.get(b).?.keys() });
    }

    var result: u32 = @intCast(bricks.items.len - supports.keys().len);

    // std.log.err("Bricks [{} ; {}] {any}", .{ bricks.items.len, supports.keys().len, bricks.items });
    for (supports.keys(), supports.values()) |k, v| {
        _ = k;
        var all_ok = true;
        for (v.items) |s| {
            const supported_by = supported_by_map.get(s).?;
            if (supported_by.keys().len > 1) {
                // std.log.err("OK", .{});
            } else {
                // std.log.err("NO: {any}", .{supported_by.keys()});
                all_ok = false;
            }
        }

        // std.log.err("{} ==> {any}", .{ k, v.items });

        if (all_ok) result += 1;
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
