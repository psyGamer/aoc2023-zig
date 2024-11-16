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
    try std.testing.expectEqual(@as(u32, 35), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u32, 46), try solve(.two, example2, std.testing.allocator));
}

const Mapping = struct {
    src: usize,
    dst: usize,
    len: usize,

    pub fn parse(in: []const u8) !Mapping {
        var result: Mapping = undefined;
        var iter = splitSca(u8, in, ' ');
        result.dst = try parseInt(usize, iter.next().?, 10);
        result.src = try parseInt(usize, iter.next().?, 10);
        result.len = try parseInt(usize, iter.next().?, 10);
        return result;
    }
};
const Range = struct {
    start: usize,
    len: usize,
};

fn parseMappings(allocator: Allocator, iter: *std.mem.TokenIterator(u8, .scalar)) !std.ArrayList(Mapping) {
    var mappings = std.ArrayList(Mapping).init(allocator);
    while (iter.next()) |line| {
        if (!std.ascii.isDigit(line[0])) break;
        try mappings.append(try Mapping.parse(line));
    }
    return mappings;
}
fn lookupMapping(in: usize, mapping: []const Mapping) usize {
    for (mapping) |map| {
        if (in >= map.src and in < map.src + map.len)
            return in - map.src + map.dst;
    }
    return in;
}
fn remapRanges(in: *std.ArrayList(Range), out: *std.ArrayList(Range), mapping: []const Mapping) !void {
    for (mapping) |map| {
        var i: usize = 0;
        while (i < in.items.len) {
            const range = in.items[i];

            if (range.start + range.len < map.src or range.start >= map.src + map.len) {
                i += 1;
                continue;
            }

            const extends_after = range.start + range.len > map.src + map.len;
            const extends_before = range.start < map.src;

            if (!extends_after and !extends_before) {
                try out.append(.{ .start = range.start - map.src + map.dst, .len = range.len });
                _ = in.orderedRemove(i);
                // Don't increment i, to iterate over the next value (which moved into i) as well.
            } else if (!extends_after and extends_before) {
                in.items[i] = .{ .start = range.start, .len = map.src - range.start };
                try out.append(.{ .start = map.dst, .len = range.start + range.len - map.src });
                i += 1;
            } else if (extends_after and !extends_before) {
                try out.append(.{ .start = range.start - map.src + map.dst, .len = map.src + map.len - range.start });
                in.items[i] = .{ .start = map.src + map.len, .len = range.start - map.src + 1 };
                i += 1;
            } else if (extends_after and extends_before) {
                in.items[i] = .{ .start = range.start, .len = map.src - range.start };
                try out.append(.{ .start = map.dst, .len = map.len });
                try in.append(.{ .start = map.src + map.len, .len = (range.start + range.len) - (map.src + map.len) });
                i += 1;
            } else {
                unreachable;
            }
        }
    }

    // Pass all unmapped ranges onto the output
    try out.appendSlice(in.items);
}

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u32 {
    var line_iter = tokenizeSca(u8, in, '\n');

    var seeds = std.ArrayList(u32).init(allocator);
    defer seeds.deinit();
    var seed_ranges = std.ArrayList(Range).init(allocator);
    defer seed_ranges.deinit();

    var seed_iter = splitSca(u8, line_iter.next().?["seeds: ".len..], ' ');
    if (part == .one) {
        while (seed_iter.next()) |seed| {
            try seeds.append(try parseInt(u32, seed, 10));
        }
    } else if (part == .two) {
        while (seed_iter.next()) |start_text| {
            try seed_ranges.append(.{
                .start = try parseInt(u32, start_text, 10),
                .len = try parseInt(u32, seed_iter.next().?, 10),
            });
        }
    }

    _ = line_iter.next(); // Skip the "seed-to-soil map:"
    var seed_to_soil = try parseMappings(allocator, &line_iter);
    defer seed_to_soil.deinit();
    var soil_to_fertilizer = try parseMappings(allocator, &line_iter);
    defer soil_to_fertilizer.deinit();
    var fertilizer_to_water = try parseMappings(allocator, &line_iter);
    defer fertilizer_to_water.deinit();
    var water_to_light = try parseMappings(allocator, &line_iter);
    defer water_to_light.deinit();
    var light_to_temperature = try parseMappings(allocator, &line_iter);
    defer light_to_temperature.deinit();
    var temperature_to_humidity = try parseMappings(allocator, &line_iter);
    defer temperature_to_humidity.deinit();
    var humidity_to_location = try parseMappings(allocator, &line_iter);
    defer humidity_to_location.deinit();

    if (part == .one) {
        var min_location: u32 = std.math.maxInt(u32);
        for (seeds.items) |seed| {
            const soil = lookupMapping(seed, seed_to_soil.items);
            const fertilizer = lookupMapping(soil, soil_to_fertilizer.items);
            const water = lookupMapping(fertilizer, fertilizer_to_water.items);
            const light = lookupMapping(water, water_to_light.items);
            const temperature = lookupMapping(light, light_to_temperature.items);
            const humidity = lookupMapping(temperature, temperature_to_humidity.items);
            const location = lookupMapping(humidity, humidity_to_location.items);
            min_location = @min(min_location, location);
        }
        return min_location;
    } else if (part == .two) {
        var soil_ranges = std.ArrayList(Range).init(allocator);
        defer soil_ranges.deinit();
        // Lists will be swapped after each mapping-set

        try remapRanges(&seed_ranges, &soil_ranges, seed_to_soil.items);
        var fertilizer_ranges = seed_ranges;
        fertilizer_ranges.clearRetainingCapacity();
        try remapRanges(&soil_ranges, &fertilizer_ranges, soil_to_fertilizer.items);
        var water_ranges = soil_ranges;
        water_ranges.clearRetainingCapacity();
        try remapRanges(&fertilizer_ranges, &water_ranges, fertilizer_to_water.items);
        var light_ranges = fertilizer_ranges;
        light_ranges.clearRetainingCapacity();
        try remapRanges(&water_ranges, &light_ranges, water_to_light.items);
        var temperature_ranges = water_ranges;
        temperature_ranges.clearRetainingCapacity();
        try remapRanges(&light_ranges, &temperature_ranges, light_to_temperature.items);
        var humidity_ranges = light_ranges;
        humidity_ranges.clearRetainingCapacity();
        try remapRanges(&temperature_ranges, &humidity_ranges, temperature_to_humidity.items);
        var location_ranges = temperature_ranges;
        location_ranges.clearRetainingCapacity();
        try remapRanges(&humidity_ranges, &location_ranges, humidity_to_location.items);

        var min_location: u32 = std.math.maxInt(u32);
        for (location_ranges.items) |range| {
            min_location = @min(min_location, range.start);
        }
        return min_location;
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
