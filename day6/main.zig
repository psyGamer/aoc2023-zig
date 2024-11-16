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

pub const std_options: std.Options = .{
    .log_level = .info,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u32, 288), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u32, 71503), try solve(.two, example2, std.testing.allocator));
}

const Race = struct { time: u64, dist: u64 };

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u32 {
    var line_iter = splitSca(u8, in, '\n');

    var time_iter = tokenizeSca(u8, line_iter.next().?["Time:     ".len..], ' ');
    var dist_iter = tokenizeSca(u8, line_iter.next().?["Distance: ".len..], ' ');

    if (part == .one) {
        var races = std.ArrayList(Race).init(allocator);
        defer races.deinit();
        while (time_iter.next()) |time| {
            try races.append(.{
                .time = try parseInt(u64, time, 10),
                .dist = try parseInt(u64, dist_iter.next().?, 10),
            });
        }

        var result: u32 = 1;
        for (races.items) |race| {
            // x = Time spent pressing; t = race.time, d = race.dist
            // (t - x) * x   > d
            // tx - x^2      > d
            // tx - x^2 -  d > 0
            // -x^2 + tx - d > 0 | a = -1 ; b = t ; c = -d
            // The graph is always open to the bottom. That means that only if it has two 0-places, there is a section above 0.
            // If there are only 1/0 0-places, the graph is always <= 0.
            // We use the quadratic formula to find those two 0-places.
            const destriminant: f32 = @floatFromInt(race.time * race.time - 4 * race.dist);
            if (destriminant <= 0) continue;

            const sqrt_desc = std.math.sqrt(destriminant);

            const x1 = (-@as(f32, @floatFromInt(race.time)) + sqrt_desc) / -2.0;
            const x2 = (-@as(f32, @floatFromInt(race.time)) - sqrt_desc) / -2.0;

            // The integers between (x1;x2) are valid numbers. (NOTE: x1/x2 are not part of the set, since they are at y=0)
            if (x1 == @ceil(x1)) {
                // x1 is an integer and using @ceil doesn't exclude it from the set
                result *= @intFromFloat(@ceil(x2 - x1 - 1));
            } else {
                // Here @ceil excludes x1 from the set
                result *= @intFromFloat(@ceil(x2 - @ceil(x1)));
            }
        }
        return result;
    } else if (part == .two) {
        var strs = std.ArrayList([]const u8).init(allocator);
        defer strs.deinit();

        while (time_iter.next()) |time| {
            try strs.append(time);
        }
        const time_text = try std.mem.join(allocator, "", strs.items);
        defer allocator.free(time_text);

        strs.clearRetainingCapacity();
        while (dist_iter.next()) |dist| {
            try strs.append(dist);
        }
        const dist_text = try std.mem.join(allocator, "", strs.items);
        defer allocator.free(dist_text);

        const race: Race = .{
            .time = try parseInt(u64, time_text, 10),
            .dist = try parseInt(u64, dist_text, 10),
        };

        // See above for explaination
        const destriminant: f64 = @floatFromInt(race.time * race.time - 4 * race.dist);
        if (destriminant <= 0) unreachable; // This doesn't make sense for this puzzle

        const sqrt_desc = std.math.sqrt(destriminant);

        const x1 = (-@as(f64, @floatFromInt(race.time)) + sqrt_desc) / -2.0;
        const x2 = (-@as(f64, @floatFromInt(race.time)) - sqrt_desc) / -2.0;

        if (x1 == @ceil(x1)) {
            // x1 is an integer and using @ceil doesn't exclude it from the set
            return @intFromFloat(@ceil(x2 - x1 - 1));
        } else {
            // Here @ceil excludes x1 from the set
            return @intFromFloat(@ceil(x2 - @ceil(x1)));
        }
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
