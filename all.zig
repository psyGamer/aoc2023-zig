const std = @import("std");

const day1 = @import("day1/main.zig");
const day2 = @import("day2/main.zig");
const day3 = @import("day3/main.zig");
const day4 = @import("day4/main.zig");
const day5 = @import("day5/main.zig");
const day6 = @import("day6/main.zig");
const day7 = @import("day7/main.zig");
const day8 = @import("day8/main.zig");
const day9 = @import("day9/main.zig");
const day10 = @import("day10/main.zig");
const day11 = @import("day11/main.zig");
const day12 = @import("day12/main.zig");
const day13 = @import("day13/main.zig");
const day14 = @import("day14/main.zig");
const day15 = @import("day15/main.zig");
const day16 = @import("day16/main.zig");
const day17 = @import("day17/main.zig");
const day18 = @import("day18/main.zig");
const day19 = @import("day19/main.zig");
const day20 = @import("day20/main.zig");
const day21 = @import("day21/main.zig");
const day22 = @import("day22/main.zig");
const day23 = @import("day23/main.zig");
const day24 = @import("day24/main.zig");
const day25 = @import("day25/main.zig");

pub const std_options: std.Options = .{
    .log_level = .info,
};

pub fn main() !void {
    // Wasting one (1) OS page is fine..
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.heap.page_allocator.free(args);

    const iter_count = if (args.len >= 2) try std.fmt.parseInt(u16, args[1], 10) else 1;
    var execution_time_ns: i128 = 0;

    // Do multiple iterations for more accurate benchmarks
    for (0..iter_count) |_| {
        const a = std.time.nanoTimestamp();

        const use_fba = false;
        var arena: std.heap.ArenaAllocator = undefined;
        const buffer = try std.heap.page_allocator.alloc(u8, std.mem.page_size * 1024);
        defer std.heap.page_allocator.free(buffer);
        var fba = std.heap.FixedBufferAllocator.init(buffer);
        const allocator = fba.allocator();

        const use_arena = false;
        // var fba: std.heap.FixedBufferAllocator = undefined;
        // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        // const allocator = arena.allocator();

        const dont_print = false;
        if (dont_print) {
            std.mem.doNotOptimizeAway(day1.solve(.one, day1.input));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(day1.solve(.two, day1.input));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day2.solve(.one, day2.input));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day2.solve(.two, day2.input));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day3.solve(.one, day3.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day3.solve(.two, day3.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day4.solve(.one, day4.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day4.solve(.two, day4.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day5.solve(.one, day5.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day5.solve(.two, day5.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day6.solve(.one, day6.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day6.solve(.two, day6.input, allocator));
            if (use_fba) fba.reset();

            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day7.solve(.one, day7.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day7.solve(.two, day7.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day8.solve(.one, day8.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day8.solve(.two, day8.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day9.solve(.one, day9.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day9.solve(.two, day9.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day10.solve(.one, day10.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day10.solve(.two, day10.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day11.solve(.one, day11.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day11.solve(.two, day11.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day12.solve(.one, day12.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day12.solve(.two, day12.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day13.solve(.one, day13.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day13.solve(.two, day13.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day14.solve(.one, day14.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day14.solve(.two, day14.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day15.solve(.one, day15.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day15.solve(.two, day15.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day16.solve(.one, day16.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day16.solve(.two, day16.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day17.solve(.one, day17.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day17.solve(.two, day17.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day18.solve(.one, day18.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day18.solve(.two, day18.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day19.solve(.one, day19.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day19.solve(.two, day19.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day20.solve(.one, day20.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day20.solve(.two, day20.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day21.solve(.one, 64, day21.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day21.solve(.two, 26501365, day21.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day22.solve(.one, day22.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day22.solve(.two, day22.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day23.solve(.one, day23.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day23.solve(.two, day23.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day24.solve(.one, 200000000000000, 400000000000000, day24.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway(try day24.solve(.two, undefined, undefined, day24.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.mem.doNotOptimizeAway(try day25.solve(day25.input, allocator));
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.mem.doNotOptimizeAway("Merry Christmas");
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
        } else {
            std.debug.print("Day 1 (Part 1): {}\n", .{day1.solve(.one, day1.input)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 1 (Part 2): {}\n", .{day1.solve(.two, day1.input)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 2 (Part 1): {}\n", .{try day2.solve(.one, day2.input)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 2 (Part 2): {}\n", .{try day2.solve(.two, day2.input)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 3 (Part 1): {}\n", .{try day3.solve(.one, day3.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 3 (Part 2): {}\n", .{try day3.solve(.two, day3.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 4 (Part 1): {}\n", .{try day4.solve(.one, day4.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 4 (Part 2): {}\n", .{try day4.solve(.two, day4.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 5 (Part 1): {}\n", .{try day5.solve(.one, day5.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 5 (Part 2): {}\n", .{try day5.solve(.two, day5.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 6 (Part 1): {}\n", .{try day6.solve(.one, day6.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 6 (Part 2): {}\n", .{try day6.solve(.two, day6.input, allocator)});
            if (use_fba) fba.reset();

            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 7 (Part 1): {}\n", .{try day7.solve(.one, day7.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 7 (Part 2): {}\n", .{try day7.solve(.two, day7.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 8 (Part 1): {}\n", .{try day8.solve(.one, day8.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 8 (Part 2): {}\n", .{try day8.solve(.two, day8.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 9 (Part 1): {}\n", .{try day9.solve(.one, day9.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 9 (Part 2): {}\n", .{try day9.solve(.two, day9.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 10 (Part 1): {}\n", .{try day10.solve(.one, day10.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 10 (Part 2): {}\n", .{try day10.solve(.two, day10.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 11 (Part 1): {}\n", .{try day11.solve(.one, day11.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 11 (Part 2): {}\n", .{try day11.solve(.two, day11.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 12 (Part 1): {}\n", .{try day12.solve(.one, day12.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 12 (Part 2): {}\n", .{try day12.solve(.two, day12.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 13 (Part 1): {}\n", .{try day13.solve(.one, day13.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 13 (Part 2): {}\n", .{try day13.solve(.two, day13.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 14 (Part 1): {}\n", .{try day14.solve(.one, day14.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 14 (Part 2): {}\n", .{try day14.solve(.two, day14.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 15 (Part 1): {}\n", .{try day15.solve(.one, day15.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 15 (Part 2): {}\n", .{try day15.solve(.two, day15.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 16 (Part 1): {}\n", .{try day16.solve(.one, day16.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 16 (Part 2): {}\n", .{try day16.solve(.two, day16.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 17 (Part 1): {}\n", .{try day17.solve(.one, day17.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 17 (Part 2): {}\n", .{try day17.solve(.two, day17.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 18 (Part 1): {}\n", .{try day18.solve(.one, day18.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 18 (Part 2): {}\n", .{try day18.solve(.two, day18.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 19 (Part 1): {}\n", .{try day19.solve(.one, day19.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 19 (Part 2): {}\n", .{try day19.solve(.two, day19.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 20 (Part 1): {}\n", .{try day20.solve(.one, day20.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 20 (Part 2): {}\n", .{try day20.solve(.two, day20.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 21 (Part 1): {}\n", .{try day21.solve(.one, 64, day21.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 21 (Part 2): {}\n", .{try day21.solve(.two, 26501365, day21.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 22 (Part 1): {}\n", .{try day22.solve(.one, day22.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 22 (Part 2): {}\n", .{try day22.solve(.two, day22.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 23 (Part 1): {}\n", .{try day23.solve(.one, day23.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 23 (Part 2): {}\n", .{try day23.solve(.two, day23.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 24 (Part 1): {}\n", .{try day24.solve(.one, 200000000000000, 400000000000000, day24.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 24 (Part 2): {}\n", .{try day24.solve(.two, undefined, undefined, day24.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);

            std.debug.print("Day 25 (Part 1): {}\n", .{try day25.solve(day25.input, allocator)});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
            std.debug.print("Day 25 (Part 2): {s}\n", .{"Merry Christmas"});
            if (use_fba) fba.reset();
            if (use_arena) _ = arena.reset(.retain_capacity);
        }
        const b = std.time.nanoTimestamp();

        execution_time_ns += b - a;
    }

    std.debug.print("\n Saved Christmas in {}ms ({}ns)", .{ @divExact(@divExact(execution_time_ns, std.time.ns_per_ms), iter_count), @divExact(execution_time_ns, iter_count) });
}
