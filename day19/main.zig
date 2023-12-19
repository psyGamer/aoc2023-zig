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
    try std.testing.expectEqual(@as(u64, 19114), try solve(.one, example1, std.testing.allocator));
}
test "Part 2" {
    // try std.testing.expectEqual(@as(u64, 6), try solve(.two, example2, std.testing.allocator));
}

const ParseState = enum { workflow, parts };

const Variable = enum { x, m, a, s };
const Comparer = enum { gt, lt };
const Rule = struct {
    variable: Variable,
    comparer: Comparer,
    other: u32,
    target: []const u8,
};
const Workflow = struct {
    rules: std.ArrayList(Rule),
    fallthrough: []const u8,
};
const MachinePart = struct { x: u32, m: u32, a: u32, s: u32 };

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    _ = part;

    var state: ParseState = .workflow;

    var workflows = std.StringHashMap(Workflow).init(allocator);
    defer {
        var iter = workflows.valueIterator();
        while (iter.next()) |w| {
            w.rules.deinit();
        }
        workflows.deinit();
    }
    var parts = std.ArrayList(MachinePart).init(allocator);
    defer parts.deinit();

    var line_iter = splitSca(u8, in, '\n');
    while (line_iter.next()) |line| {
        if (line.len == 0) {
            state = .parts;
            continue;
        }

        if (state == .workflow) {
            var workflow: Workflow = .{ .rules = std.ArrayList(Rule).init(allocator), .fallthrough = undefined };

            const name, var rest = splitOnceScalar(u8, line, '{');
            var rule_iter = splitSca(u8, rest[0..(rest.len - 1)], ',');
            while (rule_iter.next()) |rule| {
                const condition, const target = splitOnceScalar(u8, rule, ':');
                if (target.len != 0) {
                    try workflow.rules.append(.{
                        .variable = switch (condition[0]) {
                            'x' => .x,
                            'm' => .m,
                            'a' => .a,
                            's' => .s,
                            else => unreachable,
                        },
                        .comparer = switch (condition[1]) {
                            '>' => .gt,
                            '<' => .lt,
                            else => unreachable,
                        },
                        .other = try parseInt(u32, condition[2..], 10),
                        .target = target,
                    });
                } else {
                    workflow.fallthrough = condition;
                }
            }

            try workflows.put(name, workflow);
        } else if (state == .parts) {
            std.log.warn("{s}", .{line[1..(line.len - 1)]});
            // const x, const m, const a, const s = try scan("x={u32},m={u32},a={u32},s={u32}", line[1..(line.len - 1)]);
            // try parts.append(.{ .x = x, .m = m, .a = a, .s = s });

            var iter = splitSca(u8, line[1..(line.len - 1)], ',');
            try parts.append(.{
                .x = try parseInt(u32, iter.next().?[2..], 10),
                .m = try parseInt(u32, iter.next().?[2..], 10),
                .a = try parseInt(u32, iter.next().?[2..], 10),
                .s = try parseInt(u32, iter.next().?[2..], 10),
            });
        }
    }

    var result: u32 = 0;

    for (parts.items) |p| {
        std.log.err("cur {}", .{p});
        var curr_name: []const u8 = "in";
        var curr: Workflow = undefined;
        outer: while (!std.mem.eql(u8, curr_name, "A") and !std.mem.eql(u8, curr_name, "R")) {
            std.log.warn("curr {s}", .{curr_name});
            curr = workflows.get(curr_name).?;
            for (curr.rules.items) |r| {
                const a = switch (r.variable) {
                    .x => p.x,
                    .m => p.m,
                    .a => p.a,
                    .s => p.s,
                };
                if ((r.comparer == .gt and a > r.other) or (r.comparer == .lt and a < r.other)) {
                    curr_name = r.target;
                    continue :outer;
                }
            }

            curr_name = curr.fallthrough;
        }

        if (curr_name[0] == 'A') {
            result += p.x + p.m + p.a + p.s;
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
