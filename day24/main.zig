const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

pub const input = @embedFile("input.txt");
const example1 = @embedFile("example1.txt");
const example2 = @embedFile("example2.txt");

const c = @cImport({
    @cInclude("z3.h");
});

const Part = enum { one, two };

pub const std_options = struct {
    pub const log_level = .info;
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // std.log.info("Result (Part 1): {}", .{try solve(.one, 200000000000000, 400000000000000, input, allocator)});
    std.log.info("Result (Part 2): {}", .{try solve(.two, undefined, undefined, input, allocator)});
}
test "Part 1" {
    // try std.testing.expectEqual(@as(u64, 2), try solve(.one, 7, 27, example1, std.testing.allocator));
}
test "Part 2" {
    try std.testing.expectEqual(@as(u64, 6), try solve(.two, undefined, undefined, example1, std.testing.allocator));
}

const Vec3i = struct { x: i16, y: i16, z: i16 };
const Vec3u = struct { x: u64, y: u64, z: u64 };
const Vec3f = struct { x: f64, y: f64, z: f64 };

const HailStone = struct { pos: Vec3u, vel: Vec3i };
const LinearEqu = struct { m: f64, c: f64 };

pub fn solve(comptime part: Part, comptime area_min: comptime_int, comptime area_max: comptime_int, in: []const u8, allocator: Allocator) !u64 {
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

    if (part == .one) {
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
    } else if (part == .two) {
        const cfg = c.Z3_mk_config();
        const ctx = c.Z3_mk_context(cfg);

        const int_sort = c.Z3_mk_int_sort(ctx);
        const real_sort = c.Z3_mk_real_sort(ctx);
        _ = real_sort;

        if (false) { // Z3 testing
            const x = makeIntVar(ctx, "x");
            const y = makeIntVar(ctx, "y");

            const args = [_]c.Z3_ast{ c.Z3_mk_int(ctx, 3, int_sort), y };
            const eq = c.Z3_mk_eq(ctx, x, c.Z3_mk_mul(ctx, args.len, &args));
            const neq = c.Z3_mk_not(ctx, c.Z3_mk_eq(ctx, x, c.Z3_mk_int(ctx, 0, int_sort)));

            const solver = c.Z3_mk_solver(ctx);
            c.Z3_solver_assert(ctx, solver, eq);
            c.Z3_solver_assert(ctx, solver, neq);

            if (c.Z3_solver_check(ctx, solver) == c.Z3_L_TRUE) {
                const model = c.Z3_solver_get_model(ctx, solver);

                var x_val: c.Z3_ast = undefined;
                var y_val: c.Z3_ast = undefined;
                _ = c.Z3_model_eval(ctx, model, x, true, &x_val);
                _ = c.Z3_model_eval(ctx, model, y, true, &y_val);

                var x_num: c_int = undefined;
                var y_num: c_int = undefined;
                _ = c.Z3_get_numeral_int(ctx, x_val, &x_num);
                _ = c.Z3_get_numeral_int(ctx, y_val, &y_num);

                std.log.warn("Solution: x={} y={}", .{ x_num, y_num });
            }
            return 0;
        }

        // const px = makeVar(ctx, "px", int_sort);
        // const py = makeVar(ctx, "py", int_sort);
        // const pz = makeVar(ctx, "pz", int_sort);
        // const vx = makeVar(ctx, "vx", int_sort);
        // const vy = makeVar(ctx, "vy", int_sort);
        // const vz = makeVar(ctx, "vz", int_sort);

        const px = makeVar(ctx, "px", int_sort);
        const py = makeVar(ctx, "py", int_sort);
        const pz = makeVar(ctx, "pz", int_sort);
        const vx = makeVar(ctx, "vx", int_sort);
        const vy = makeVar(ctx, "vy", int_sort);
        const vz = makeVar(ctx, "vz", int_sort);

        // var equs = std.ArrayList(c.Z3_ast).init(allocator);
        // defer equs.deinit();
        // equs.resize(hail_stones.items.len * 3);

        var mul_args = [_]c.Z3_ast{ undefined, undefined };
        var add_args = [_]c.Z3_ast{ undefined, undefined };

        // var mul_args = [_]c.Z3_ast{ vx, t };
        // var add_args = [_]c.Z3_ast{ px, c.Z3_mk_mul(ctx, mul_args.len, &mul_args) };
        // const rx_equ = c.Z3_mk_add(ctx, add_args.len, &add_args);
        // mul_args[0] = vy;
        // add_args = .{ py, c.Z3_mk_mul(ctx, mul_args.len, &mul_args) };
        // const ry_equ = c.Z3_mk_add(ctx, add_args.len, &add_args);

        // const x_mul_args = [_]c.Z3_ast{ vx, t };
        // const x_add_args = [_]c.Z3_ast{ px, c.Z3_mk_mul(ctx, x_mul_args.len, &x_mul_args) };
        // const rx_equ = c.Z3_mk_add(ctx, x_add_args.len, &x_add_args);
        // std.log.warn("rx = {s} ", .{c.Z3_ast_to_string(ctx, rx_equ)});

        // const y_mul_args = [_]c.Z3_ast{ vy, t };
        // const y_add_args = [_]c.Z3_ast{ py, c.Z3_mk_mul(ctx, y_mul_args.len, &y_mul_args) };
        // const ry_equ = c.Z3_mk_add(ctx, y_add_args.len, &y_add_args);
        // std.log.warn("rx = {s} ry = {s} ", .{ c.Z3_ast_to_string(ctx, rx_equ), c.Z3_ast_to_string(ctx, ry_equ) });

        // const z_mul_args = [_]c.Z3_ast{ vz, t };
        // const z_add_args = [_]c.Z3_ast{ pz, c.Z3_mk_mul(ctx, z_mul_args.len, &z_mul_args) };
        // const rz_equ = c.Z3_mk_add(ctx, z_add_args.len, &z_add_args);

        // std.log.warn("rx = {s} ry = {s} rz = {s}", .{ c.Z3_ast_to_string(ctx, rx_equ), c.Z3_ast_to_string(ctx, ry_equ), c.Z3_ast_to_string(ctx, rz_equ) });

        const solver = c.Z3_mk_solver(ctx);

        // hail_stones.items.len = 2;

        var prev_t: ?c.Z3_ast = null;

        for (hail_stones.items, 0..) |hail_stone, i| {
            const t_name = try std.fmt.allocPrintZ(allocator, "t{}", .{i});
            defer allocator.free(t_name);
            const t = makeIntVar(ctx, t_name);
            mul_args[1] = t;

            mul_args[0] = vx;
            add_args = .{ px, c.Z3_mk_mul(ctx, mul_args.len, &mul_args) };
            const rx_equ = c.Z3_mk_add(ctx, add_args.len, &add_args);

            mul_args[0] = vy;
            add_args = .{ py, c.Z3_mk_mul(ctx, mul_args.len, &mul_args) };
            const ry_equ = c.Z3_mk_add(ctx, add_args.len, &add_args);

            mul_args[0] = vz;
            add_args = .{ pz, c.Z3_mk_mul(ctx, mul_args.len, &mul_args) };
            const rz_equ = c.Z3_mk_add(ctx, add_args.len, &add_args);

            // mul_args[0] = c.Z3_mk_int(ctx, hail_stone.vel.y, int_sort);
            // add_args = .{ c.Z3_mk_unsigned_int64(ctx, hail_stone.pos.y, int_sort), c.Z3_mk_mul(ctx, mul_args.len, &mul_args) };
            // const hy_equ = c.Z3_mk_add(ctx, add_args.len, &add_args);

            // const eq = c.Z3_mk_eq(ctx, ry_equ, hy_equ);
            // std.log.warn("EQU: {s}", .{c.Z3_ast_to_string(ctx, eq)});

            mul_args[0] = c.Z3_mk_int(ctx, hail_stone.vel.x, int_sort);
            add_args = .{ c.Z3_mk_unsigned_int64(ctx, hail_stone.pos.x, int_sort), c.Z3_mk_mul(ctx, mul_args.len, &mul_args) };
            const hx_equ = c.Z3_mk_add(ctx, add_args.len, &add_args);
            mul_args[0] = c.Z3_mk_int(ctx, hail_stone.vel.y, int_sort);
            add_args = .{ c.Z3_mk_unsigned_int64(ctx, hail_stone.pos.y, int_sort), c.Z3_mk_mul(ctx, mul_args.len, &mul_args) };
            const hy_equ = c.Z3_mk_add(ctx, add_args.len, &add_args);
            mul_args[0] = c.Z3_mk_int(ctx, hail_stone.vel.z, int_sort);
            add_args = .{ c.Z3_mk_unsigned_int64(ctx, hail_stone.pos.z, int_sort), c.Z3_mk_mul(ctx, mul_args.len, &mul_args) };
            const hz_equ = c.Z3_mk_add(ctx, add_args.len, &add_args);

            // std.log.warn("X: {s}", .{c.Z3_ast_to_string(ctx, c.Z3_mk_eq(ctx, rx_equ, hx_equ))});
            // std.log.warn("Y: {s}", .{c.Z3_ast_to_string(ctx, c.Z3_mk_eq(ctx, ry_equ, hy_equ))});
            // std.log.warn("Z: {s}", .{c.Z3_ast_to_string(ctx, c.Z3_mk_eq(ctx, rz_equ, hz_equ))});

            // equs[3 * i + 0] = c.Z3_mk_eq(ctx, rx_equ, hx_equ);
            // equs[3 * i + 1] = c.Z3_mk_eq(ctx, ry_equ, hy_equ);
            // equs[3 * i + 2] = c.Z3_mk_eq(ctx, rz_equ, hz_equ);

            c.Z3_solver_assert(ctx, solver, c.Z3_mk_eq(ctx, rx_equ, hx_equ));
            c.Z3_solver_assert(ctx, solver, c.Z3_mk_eq(ctx, ry_equ, hy_equ));
            c.Z3_solver_assert(ctx, solver, c.Z3_mk_eq(ctx, rz_equ, hz_equ));
            // if (prev_t) |prev| {
            //     c.Z3_solver_assert(ctx, solver, )
            // }

            prev_t = t;
        }

        if (c.Z3_solver_check(ctx, solver) == c.Z3_L_TRUE) {
            const model = c.Z3_solver_get_model(ctx, solver);

            // var px_val: c.Z3_ast = undefined;
            // var py_val: c.Z3_ast = undefined;
            // var pz_val: c.Z3_ast = undefined;
            // _ = c.Z3_model_eval(ctx, model, px, true, &px_val);
            // _ = c.Z3_model_eval(ctx, model, py, true, &py_val);
            // _ = c.Z3_model_eval(ctx, model, py, true, &pz_val);

            // var px_num: c_int = undefined;
            // var py_num: c_int = undefined;
            // var pz_num: c_int = undefined;
            // _ = c.Z3_get_numeral_int(ctx, px_val, &px_num);
            // _ = c.Z3_get_numeral_int(ctx, py_val, &py_num);
            // _ = c.Z3_get_numeral_int(ctx, pz_val, &pz_num);

            // std.log.warn("Solution: px={} py={} pz={}", .{ px_num, py_num, pz_num });
            std.log.warn("Solution: px={} py={} pz={} vx={} vy={} vz={}", .{
                getValue(ctx, model, px),
                getValue(ctx, model, py),
                getValue(ctx, model, pz),
                getValue(ctx, model, vx),
                getValue(ctx, model, vy),
                getValue(ctx, model, vz),
            });
            return @intCast(getValue(ctx, model, px) + getValue(ctx, model, py) + getValue(ctx, model, pz));
        } else {
            std.log.err("FAIL", .{});
        }

        return 0;
    }
    unreachable;
}

fn makeVar(ctx: c.Z3_context, name: [*:0]const u8, ty: c.Z3_sort) c.Z3_ast {
    const s = c.Z3_mk_string_symbol(ctx, name);
    return c.Z3_mk_const(ctx, s, ty);
}

fn makeIntVar(ctx: c.Z3_context, name: [*:0]const u8) c.Z3_ast {
    const ty = c.Z3_mk_int_sort(ctx);
    const s = c.Z3_mk_string_symbol(ctx, name);
    return c.Z3_mk_const(ctx, s, ty);
}
fn makeEqu(ctx: c.Z3_context, pos: c.Z3_ast, vel: c.Z3_ast, t: c.Z3_ast) c.Z3_ast {
    const mul_args = [_]c.Z3_ast{ vel, t };
    const add_args = [_]c.Z3_ast{ pos, c.Z3_mk_mul(ctx, mul_args.len, &mul_args) };
    return c.Z3_mk_add(ctx, add_args.len, &add_args);
}
fn getValue(ctx: c.Z3_context, model: c.Z3_model, x: c.Z3_ast) i64 {
    var val: c.Z3_ast = undefined;
    _ = c.Z3_model_eval(ctx, model, x, true, &val);
    var num: i64 = undefined;
    _ = c.Z3_get_numeral_int64(ctx, val, &num);
    // _ = c.Z3_get_numeral_int(ctx, val, &num);
    return num;
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
