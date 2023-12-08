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
    // std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    std.testing.log_level = .debug;
    try std.testing.expectEqual(@as(u32, 35), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    std.testing.log_level = .debug;
    // try std.testing.expectEqual(@as(u32, 8), try solve(.two, example2, std.testing.allocator));
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

fn solve(part: Part, in: []const u8, allocator: Allocator) !u32 {
    var line_iter = tokenizeSca(u8, in, '\n');

    var seeds = std.ArrayList(u32).init(allocator);
    defer seeds.deinit();
    var seed_iter = splitSca(u8, line_iter.next().?["seeds: ".len..], ' ');
    while (seed_iter.next()) |seed| {
        try seeds.append(try parseInt(u32, seed, 10));
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

    _ = part;
    return min_location;
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
