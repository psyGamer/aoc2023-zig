const std = @import("std");

const input = @embedFile("day1_input.txt");
// const input = @embedFile("day1_example.txt");

pub fn main() !void {
    var sum: u32 = 0;
    var iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (iter.next()) |line| {
        var first: u8 = std.math.maxInt(u8);
        var last: u8 = std.math.maxInt(u8);

        for (line) |char| {
            if (char >= '0' and char <= '9') {
                if (first == std.math.maxInt(u8)) {
                    // First number
                    std.debug.print("{c} ", .{char});
                    first = char - '0';
                    last = first;
                } else {
                    // Second number
                    last = char - '0';
                    std.debug.print("{c} ", .{char});
                }
            }
        }
        const value = first * 10 + last;
        std.debug.print("{}\n", .{value});
        sum += value;
    }
    std.debug.print("{}\n", .{sum});
}
