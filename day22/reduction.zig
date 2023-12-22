const std = @import("std");
const Allocator = std.mem.Allocator;

pub const input = undefined;

const Part = enum { two };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    std.log.info("Result (Part 2): {}", .{try solve(.two, input, allocator)});
}

const Brick = struct { other: void, supported_by: std.AutoArrayHashMap(Brick, void) };

pub fn solve(comptime part: Part, in: []const u8, allocator: Allocator) !u64 {
    _ = in;
    _ = part;

    var bricks = std.ArrayList(Brick).init(allocator);
    defer bricks.deinit();
}
