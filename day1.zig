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

        var i: usize = 0;
        while (i < line.len) {
            var number = b: {
                if (isSpelledNumber(line[i..])) |spelled| {
                    i += spelled.advance;
                    break :b spelled.number;
                }
                i += 1;
                break :b line[i] - '0';
            };
            // number >= 1 is implicitly true
            if (number <= 9) {
                if (first == std.math.maxInt(u8)) {
                    first = number;
                    last = number;
                    continue;
                }
                last = number;
            }
        }
        sum += first * 10 + last;
    }
    std.debug.print("{}\n", .{sum});
}

const SpelledResult = struct { number: u8, advance: u8 };
fn isSpelledNumber(string: []const u8) ?SpelledResult {
    return if (std.mem.indexOf(u8, string, "one") == 0)
        .{ .number = 1, .advance = 3 }
    else if (std.mem.indexOf(u8, string, "two") == 0)
        .{ .number = 2, .advance = 3 }
    else if (std.mem.indexOf(u8, string, "three") == 0)
        .{ .number = 3, .advance = 5 }
    else if (std.mem.indexOf(u8, string, "four") == 0)
        .{ .number = 4, .advance = 4 }
    else if (std.mem.indexOf(u8, string, "five") == 0)
        .{ .number = 5, .advance = 4 }
    else if (std.mem.indexOf(u8, string, "six") == 0)
        .{ .number = 6, .advance = 3 }
    else if (std.mem.indexOf(u8, string, "seven") == 0)
        .{ .number = 7, .advance = 5 }
    else if (std.mem.indexOf(u8, string, "eight") == 0)
        .{ .number = 8, .advance = 5 }
    else if (std.mem.indexOf(u8, string, "nine") == 0)
        .{ .number = 9, .advance = 4 }
    else
        null;
}
