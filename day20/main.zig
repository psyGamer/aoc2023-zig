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

    std.log.info("Result (Part 1): {}", .{try solve(.one, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}
test "Part 1" {
    // try std.testing.expectEqual(@as(u64, 32000000), try solve(.one, example1, std.testing.allocator));
    try std.testing.expectEqual(@as(u64, 11687500), try solve(.one, example2, std.testing.allocator));
}
test "Part 2" {
    // try std.testing.expectEqual(@as(u64, 6), try solve(.two, example2, std.testing.allocator));
}

const ModuleDefinition = struct {
    const Type = enum { broadcaster, flip_flop, conjunction };

    type: Type,
    name: []const u8,
    targets: [][]const u8,
};

const State = enum {
    low,
    high,

    pub fn toggle(state: State) State {
        return switch (state) {
            .low => .high,
            .high => .low,
        };
    }
};
const Pulse = struct { to: []const u8, from: []const u8, state: State };

const Module = union(enum) {
    broadcaster: struct {
        targets: [][]const u8,
    },
    flip_flop: struct {
        curr_state: State,
        targets: [][]const u8,
    },
    conjunction: struct {
        curr_states: std.StringArrayHashMap(State),
        targets: [][]const u8,
    },
};

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    var definitions = std.ArrayList(ModuleDefinition).init(allocator);
    defer {
        for (definitions.items) |m| {
            allocator.free(m.targets);
        }
        definitions.deinit();
    }

    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| {
        const name, const target_text = splitOnce(u8, line, " -> ");
        const typ: ModuleDefinition.Type = switch (name[0]) {
            '%' => .flip_flop,
            '&' => .conjunction,
            else => .broadcaster,
        };

        var target_iter = splitSeq(u8, target_text, ", ");
        var targets = std.ArrayList([]const u8).init(allocator);
        defer targets.deinit();
        while (target_iter.next()) |t| {
            try targets.append(t);
        }

        try definitions.append(.{
            .type = typ,
            .name = if (typ == .broadcaster) name else name[1..],
            .targets = try targets.toOwnedSlice(),
        });
    }

    var modules = std.StringHashMap(Module).init(allocator);
    defer {
        var iter = modules.valueIterator();
        while (iter.next()) |k| {
            if (k.* != .conjunction) continue;
            k.conjunction.curr_states.deinit();
        }
        modules.deinit();
    }

    for (definitions.items) |def| {
        try modules.put(def.name, switch (def.type) {
            .broadcaster => .{ .broadcaster = .{ .targets = def.targets } },
            .flip_flop => .{ .flip_flop = .{ .curr_state = .low, .targets = def.targets } },
            .conjunction => .{ .conjunction = .{ .curr_states = std.StringArrayHashMap(State).init(allocator), .targets = def.targets } },
        });
    }

    var rx_parent: Module = undefined;
    for (definitions.items) |def| {
        for (def.targets) |t| {
            if (std.mem.eql(u8, t, "rx")) {
                rx_parent = modules.get(def.name).?;
            }
            if (modules.getPtr(t)) |module| {
                if (module.* != .conjunction) continue;
                try module.conjunction.curr_states.put(def.name, .low);
            }
        }
    }

    var low_pulses: u32 = 0;
    var high_pulses: u32 = 0;

    var fifo = std.fifo.LinearFifo(Pulse, .Dynamic).init(allocator);
    defer fifo.deinit();

    const cycle_keys = rx_parent.conjunction.curr_states.keys();
    var cycle_points = try allocator.alloc(?u64, cycle_keys.len);
    defer allocator.free(cycle_points);
    @memset(cycle_points, null);
    var remaining_cycles = cycle_keys.len;

    var i: usize = 0;
    while (true) : (i += 1) {
        if (part == .one and i >= 1000) break;

        try fifo.writeItem(.{ .to = "broadcaster", .from = undefined, .state = .low });

        while (fifo.readItem()) |p| {
            if (p.state == .low) {
                low_pulses += 1;
            } else {
                high_pulses += 1;
            }

            if (p.state == .high) {
                for (cycle_keys, 0..) |k, j| {
                    if (std.mem.eql(u8, k, p.from) and cycle_points[j] == null) {
                        cycle_points[j] = @intCast(i + 1);
                        remaining_cycles -= 1;
                        break;
                    }
                }
                if (remaining_cycles == 0) {
                    return lcmSlice(cycle_points);
                }
            }

            const module = modules.getPtr(p.to) orelse continue;
            switch (module.*) {
                .broadcaster => |m| {
                    for (m.targets) |t| {
                        try fifo.writeItem(.{ .to = t, .from = p.to, .state = p.state });
                    }
                },
                .flip_flop => |*m| {
                    if (p.state == .high) continue; // Ignored
                    m.curr_state = m.curr_state.toggle();
                    for (m.targets) |t| {
                        try fifo.writeItem(.{ .to = t, .from = p.to, .state = m.curr_state });
                    }
                },
                .conjunction => |*m| {
                    try m.curr_states.put(p.from, p.state);

                    var all_high = true;
                    for (m.curr_states.values()) |val| {
                        if (val != .high) {
                            all_high = false;
                            break;
                        }
                    }

                    if (all_high) {
                        for (m.targets) |t| {
                            try fifo.writeItem(.{ .to = t, .from = p.to, .state = .low });
                        }
                    } else {
                        for (m.targets) |t| {
                            try fifo.writeItem(.{ .to = t, .from = p.to, .state = .high });
                        }
                    }
                },
            }
        }
    }

    return high_pulses * low_pulses;
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
fn lcmSlice(numbers: []const ?u64) u64 {
    return if (numbers.len > 2)
        lcm(numbers[0].?, lcmSlice(numbers[1..]))
    else
        lcm(numbers[0].?, numbers[1].?);
}

fn splitOnce(comptime T: type, haystack: []const T, needle: []const T) struct { []const T, []const T } {
    const idx = std.mem.indexOf(T, haystack, needle) orelse return .{ haystack, &.{} };
    return .{ haystack[0..idx], haystack[(idx + needle.len)..] };
}
fn splitOnceScalar(comptime T: type, buffer: []const T, delimiter: T) struct { []const T, []const T } {
    const idx = std.mem.indexOfScalar(T, buffer, delimiter) orelse return .{ buffer, &.{} };
    return .{ buffer[0..idx], buffer[(idx + 1)..] };
}
