const std = @import("std");

const input = @embedFile("day1_input.txt");
// const input = @embedFile("day1_example1.txt");
// const input = @embedFile("day1_example2.txt");

pub fn main() !void {
    var sum: u32 = 0;
    var iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (iter.next()) |line| {
        var first: u8 = std.math.maxInt(u8);
        var last: u8 = std.math.maxInt(u8);

        for (line, 0..) |char, i| {
            var number: u8 = char - '0';
            if (isSpelledNumber(line[i..])) |n| {
                number = n;
            }

            if (number >= 0 and number <= 9) {
                if (first == std.math.maxInt(u8)) {
                    // First number
                    first = number;
                    last = first;
                } else {
                    // Second number
                    last = number;
                }
            }
        }
        const value = first * 10 + last;
        std.debug.print("{}\n", .{value});
        sum += value;
    }
    std.debug.print("{}\n", .{sum});
}

fn isSpelledNumber(string: []const u8) ?u8 {
    return if (std.mem.indexOf(u8, string, "one") == 0)
        1
    else if (std.mem.indexOf(u8, string, "two") == 0)
        2
    else if (std.mem.indexOf(u8, string, "three") == 0)
        3
    else if (std.mem.indexOf(u8, string, "four") == 0)
        4
    else if (std.mem.indexOf(u8, string, "five") == 0)
        5
    else if (std.mem.indexOf(u8, string, "six") == 0)
        6
    else if (std.mem.indexOf(u8, string, "seven") == 0)
        7
    else if (std.mem.indexOf(u8, string, "eight") == 0)
        8
    else if (std.mem.indexOf(u8, string, "nine") == 0)
        9
    else
        null;
}
