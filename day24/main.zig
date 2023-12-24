const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

pub const input = @embedFile("input.txt");
const example1 = @embedFile("example1.txt");
const example2 = @embedFile("example2.txt");

const Part = enum { one, two };

pub const std_options = struct {
    pub const log_level = .info;
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Result (Part 1): {}", .{try solve(.one, 200000000000000, 400000000000000, input, allocator)});
    // std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    try std.testing.expectEqual(@as(u64, 2), try solve(.one, 7, 27, example1, std.testing.allocator));
}
test "Part 2" {
    // try std.testing.expectEqual(@as(u64, 6), try solve(.two, example2, std.testing.allocator));
}

const Vec3i = struct { x: i16, y: i16, z: i16 };
const Vec3u = struct { x: u64, y: u64, z: u64 };
const Vec3f = struct { x: f64, y: f64, z: f64 };

const HailStone = struct { pos: Vec3u, vel: Vec3i };
const LinearEqu = struct { m: f64, c: f64 };

pub fn solve(comptime part: Part, comptime area_min: comptime_int, comptime area_max: comptime_int, in: []const u8, allocator: Allocator) !u64 {
    _ = part;

    var hail_stones = std.ArrayList(HailStone).init(allocator);
    defer hail_stones.deinit();

    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| {
        var tilde_iter = splitSeq(u8, line, " @ ");

        var comma_iter = splitSeq(u8, tilde_iter.next().?, ", ");
        const pos: Vec3u = .{
            .x = try parseInt(u64, trim(u8, comma_iter.next().?, " "), 10),
            .y = try parseInt(u64, trim(u8, comma_iter.next().?, " "), 10),
            .z = try parseInt(u64, trim(u8, comma_iter.next().?, " "), 10),
        };

        comma_iter = splitSeq(u8, tilde_iter.next().?, ", ");
        const vel: Vec3i = .{
            .x = try parseInt(i16, trim(u8, comma_iter.next().?, " "), 10),
            .y = try parseInt(i16, trim(u8, comma_iter.next().?, " "), 10),
            .z = try parseInt(i16, trim(u8, comma_iter.next().?, " "), 10),
        };

        try hail_stones.append(.{ .pos = pos, .vel = vel });
    }

    var equs = std.ArrayList(LinearEqu).init(allocator);
    defer equs.deinit();
    try equs.resize(hail_stones.items.len);

    for (hail_stones.items, equs.items) |hail, *equ| {
        // pos,val = (vely/velx)(x - px) + py
        // pos,val = (vely/velx)x - (vely/velx)px + py
        // pos,val = (vely/velx)x + (py - (vely/velx)px)
        equ.m = @as(f64, @floatFromInt(hail.vel.y)) / @as(f64, @floatFromInt(hail.vel.x));
        equ.c = @as(f64, @floatFromInt(hail.pos.y)) - equ.m * @as(f64, @floatFromInt(hail.pos.x));
        // std.log.warn("{} -> {}", .{ hail, equ });
    }

    var result: u32 = 0;

    for (hail_stones.items, equs.items, 0..) |ah, a, i| {
        for (hail_stones.items[i..], equs.items[i..], i..) |bh, b, j| {
            if (i == j) continue;
            // ma*x + ca = mb*x + cb
            // ma*x + ca - cb = mb*x
            // ca - cb = mb*x - ma*x
            // ca - cb = x(mb - ma)
            // (ca - cb) / (mb - ma) = x
            const x = (a.c - b.c) / (b.m - a.m);
            const y = a.m * x + a.c;
            // std.log.warn("{} + {} at {d},{d}", .{ a, b, x, y });

            if (std.math.sign(@as(f64, @floatFromInt(ah.vel.x))) != std.math.sign(x - @as(f64, @floatFromInt(ah.pos.x))) or
                std.math.sign(@as(f64, @floatFromInt(ah.vel.y))) != std.math.sign(y - @as(f64, @floatFromInt(ah.pos.y))) or
                std.math.sign(@as(f64, @floatFromInt(bh.vel.x))) != std.math.sign(x - @as(f64, @floatFromInt(bh.pos.x))) or
                std.math.sign(@as(f64, @floatFromInt(bh.vel.y))) != std.math.sign(y - @as(f64, @floatFromInt(bh.pos.y))))
            {
                continue;
            }
            if (x >= area_min and x <= area_max and y >= area_min and y <= area_max) result += 1;
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
