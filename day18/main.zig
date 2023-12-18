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
    try std.testing.expectEqual(@as(u64, 62), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 952408144115), try solve(.two, example1, std.testing.allocator));
}

const Vec2i = struct { x: i32, y: i32 };

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    var nodes = std.ArrayList(Vec2i).init(allocator);
    defer nodes.deinit();
    try nodes.append(.{ .x = 0, .y = 0 });

    var last_dir: u8 = 0;
    var last_pos: Vec2i = nodes.getLast();

    const clock_wise = b: {
        const first = in[0];
        last_dir = in[lastIndexOf(u8, in[0..(in.len - 1)], '\n').? + 1];
        // std.log.err("{c} {c}", .{ first, last_dir });
        break :b switch (first) {
            'L' => switch (last_dir) {
                'U' => false,
                'D' => true,
                else => unreachable,
            },
            'R' => switch (last_dir) {
                'U' => true,
                'D' => false,
                else => unreachable,
            },
            'U' => switch (last_dir) {
                'R' => false,
                'L' => true,
                else => unreachable,
            },
            'D' => switch (last_dir) {
                'R' => true,
                'L' => false,
                else => unreachable,
            },
            else => unreachable,
        };
    };

    var line_iter = tokenizeSca(u8, in, '\n');
    while (line_iter.next()) |line| {
        var dir: u8 = undefined;
        var dist: u31 = undefined;
        if (part == .one) {
            const dir_text, var rest = splitOnceScalar(u8, line, ' ');
            dir = dir_text[0];
            const dist_text, rest = splitOnceScalar(u8, rest, ' ');
            dist = try parseInt(u8, dist_text, 10) * 2;
        } else if (part == .two) {
            _, const hex = splitOnceScalar(u8, line, '#');
            dir = switch (hex[5]) {
                '0' => 'R',
                '1' => 'D',
                '2' => 'L',
                '3' => 'U',
                else => unreachable,
            };
            dist = try parseInt(u31, hex[0..5], 16) * 2;
        }

        const offset: Vec2i = if (clock_wise)
            switch (last_dir) {
                'L' => switch (dir) {
                    'U' => .{ .x = -1, .y = 1 },
                    'D' => .{ .x = 1, .y = 1 },
                    else => unreachable,
                },
                'R' => switch (dir) {
                    'U' => .{ .x = -1, .y = -1 },
                    'D' => .{ .x = 1, .y = -1 },
                    else => unreachable,
                },
                'U' => switch (dir) {
                    'L' => .{ .x = -1, .y = 1 },
                    'R' => .{ .x = -1, .y = -1 },
                    else => unreachable,
                },
                'D' => switch (dir) {
                    'L' => .{ .x = 1, .y = 1 },
                    'R' => .{ .x = 1, .y = -1 },
                    else => unreachable,
                },
                else => unreachable,
            }
        else switch (last_dir) {
            'L' => switch (dir) {
                'U' => .{ .x = 1, .y = -1 },
                'D' => .{ .x = -1, .y = -1 },
                else => unreachable,
            },
            'R' => switch (dir) {
                'U' => .{ .x = 1, .y = 1 },
                'D' => .{ .x = -1, .y = 1 },
                else => unreachable,
            },
            'U' => switch (dir) {
                'L' => .{ .x = 1, .y = -1 },
                'R' => .{ .x = 1, .y = 1 },
                else => unreachable,
            },
            'D' => switch (dir) {
                'L' => .{ .x = -1, .y = -1 },
                'R' => .{ .x = -1, .y = 1 },
                else => unreachable,
            },
            else => unreachable,
        };
        _ = offset;
        // std.log.warn("{s} {c} {} {}", .{ line, last_dir, offset, last_pos });
        last_dir = dir;

        // nodes.items[nodes.items.len - 1].x += offset.x;
        // nodes.items[nodes.items.len - 1].y += offset.y;

        last_pos = switch (dir) {
            'L' => .{ .x = last_pos.x - dist, .y = last_pos.y },
            'R' => .{ .x = last_pos.x + dist, .y = last_pos.y },
            'U' => .{ .x = last_pos.x, .y = last_pos.y - dist },
            'D' => .{ .x = last_pos.x, .y = last_pos.y + dist },
            else => unreachable,
        };
        try nodes.append(last_pos);

        var x: f32 = @as(f32, @floatFromInt(nodes.items[nodes.items.len - 2].x)) / 2.0;
        _ = x;
        var y: f32 = @as(f32, @floatFromInt(nodes.items[nodes.items.len - 2].y)) / 2.0;
        _ = y;
        // std.log.warn("{c} {} : {d} {d}", .{ dir, dist / 2, x, y });
    }

    // Finish the loop and ensure its counter-clock-wise
    nodes.items[nodes.items.len - 1] = nodes.items[0];
    // std.log.warn("{any}", .{nodes});

    // Shoelace Algorithm
    const SumInt = i64;
    var sum1: SumInt = 0;
    var sum2: SumInt = 0;
    for (0..(nodes.items.len - 1)) |i| {
        sum1 += @as(SumInt, nodes.items[i].x) * @as(SumInt, nodes.items[i + 1].y);
        sum2 += @as(SumInt, nodes.items[i].y) * @as(SumInt, nodes.items[i + 1].x);
    }
    // Connect first and last
    sum1 += nodes.getLast().x * nodes.items[0].y;
    sum2 += nodes.items[0].y * nodes.getLast().x;
    const area = @abs(sum1 - sum2) / 2;

    // Surcumrefence of the polygon
    var sum3: u64 = 0;
    for (0..(nodes.items.len - 1)) |i| {
        sum3 += @abs(@as(SumInt, nodes.items[i + 1].x) - @as(SumInt, nodes.items[i].x));
        sum3 += @abs(@as(SumInt, nodes.items[i + 1].y) - @as(SumInt, nodes.items[i].y));
    }
    // std.log.warn("{} {}", .{ area, sum3 });

    return (area + sum3) / 4 + 1; // We inflated everything by 2 => / 4 area
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

fn ScanTuple(comptime fmt: []const u8) type {
    var info: std.builtin.Type.Struct = .{
        .layout = .Auto,
        .fields = &.{},
        .decls = &.{},
        .is_tuple = true,
    };

    comptime var i = 0;
    inline while (i < fmt.len) {
        inline while (i < fmt.len) : (i += 1) {
            switch (fmt[i]) {
                '{', '}' => break,
                else => {},
            }
        }

        comptime var unescape_brace = false;

        // Handle {{ and }}, those are un-escaped as single braces
        if (i + 1 < fmt.len and fmt[i + 1] == fmt[i]) {
            unescape_brace = true;
            // Make the first brace part of the literal and skip both
            i += 2;
        }

        // We've already skipped the other brace, restart the loop
        if (unescape_brace) continue;

        if (i >= fmt.len) break;

        if (fmt[i] == '}') {
            @compileError("missing opening {");
        }

        // Get past the {
        comptime std.debug.assert(fmt[i] == '{');
        i += 1;

        const fmt_begin = i;
        // Find the closing brace
        inline while (i < fmt.len and fmt[i] != '}') : (i += 1) {}
        const fmt_end = i;

        if (i >= fmt.len) {
            @compileError("missing closing }");
        }

        // Get past the }
        comptime std.debug.assert(fmt[i] == '}');
        i += 1;

        switch (fmt[fmt_begin]) {
            'i' => {
                const bits = try std.fmt.parseInt(u16, fmt[(fmt_begin + 1)..fmt_end], 10);
                const int_type = std.meta.Int(.signed, bits);
                const field: std.builtin.Type.StructField = .{
                    .name = std.fmt.comptimePrint("{}", .{info.fields.len}),
                    .type = int_type,
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = @alignOf(int_type),
                };
                info.fields = info.fields ++ [_]std.builtin.Type.StructField{field};
            },
            'u' => {
                const bits = try std.fmt.parseInt(u16, fmt[(fmt_begin + 1)..fmt_end], 10);
                const int_type = std.meta.Int(.unsigned, bits);
                const field: std.builtin.Type.StructField = .{
                    .name = std.fmt.comptimePrint("{}", .{info.fields.len}),
                    .type = int_type,
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = @alignOf(int_type),
                };
                info.fields = info.fields ++ [_]std.builtin.Type.StructField{field};
            },
            else => @compileError("Unsupported target type " ++ fmt[fmt_begin..fmt_end]),
        }
    }

    return @Type(.{ .Struct = info });
}
fn scan(comptime fmt: []const u8, buffer: []const u8) !ScanTuple(fmt) {
    var result: ScanTuple(fmt) = undefined;
    var read_idx: usize = 0;
    comptime var arg_idx: usize = 0;

    @setEvalBranchQuota(2000000);
    comptime var i = 0;
    inline while (i < fmt.len) {
        const start_index = i;

        inline while (i < fmt.len) : ({
            i += 1;
            read_idx += 1;
        }) {
            switch (fmt[i]) {
                '{', '}' => break,
                else => {},
            }
        }

        comptime var end_index = i;
        comptime var unescape_brace = false;

        // Handle {{ and }}, those are un-escaped as single braces
        if (i + 1 < fmt.len and fmt[i + 1] == fmt[i]) {
            unescape_brace = true;
            // Make the first brace part of the literal...
            end_index += 1;
            // ...and skip both
            i += 2;
            read_idx += 2;
        }

        // Write out the literal
        if (start_index != end_index) {
            // try writer.writeAll(fmt[start_index..end_index]);
            std.log.info("!{s}! {} {}", .{ fmt[start_index..end_index], start_index, end_index });
        }

        // Get past the {
        comptime std.debug.assert(fmt[i] == '{');
        i += 1;
        read_idx += 1;

        const fmt_begin = i;
        _ = fmt_begin;
        // Find the closing brace
        inline while (i < fmt.len and fmt[i] != '}') : (i += 1) {}
        const fmt_end = i;
        _ = fmt_end;

        if (i >= fmt.len) {
            @compileError("missing closing }");
        }

        // Get past the }
        comptime std.debug.assert(fmt[i] == '}');
        i += 1;
        read_idx += 1;

        const arg_type = @typeInfo(ScanTuple(fmt)).Struct.fields[arg_idx].type;
        switch (@typeInfo(arg_type)) {
            .Int => {
                var end_int_idx = read_idx;
                while (end_int_idx < buffer.len) : (end_int_idx += 1) {
                    if (!std.ascii.isDigit(buffer[end_int_idx])) break;
                }
                result[arg_idx] = try std.fmt.parseInt(arg_type, buffer[read_idx..end_int_idx], 0);
                read_idx = end_int_idx - 2;
            },
            else => @compileError("Unsupported target type " ++ @typeName(arg_type)),
        }

        arg_idx += 1;
    }

    return result;
}
