const std = @import("std");
const Allocator = std.mem.Allocator;

/// A thin wrapper around a 2D array
pub fn Array2D(comptime T: type) type {
    return struct {
        const Self = @This();

        data: []T,
        width: usize,
        height: usize,

        pub fn init(allocator: Allocator, width: usize, height: usize) !Self {
            return .{
                .data = try allocator.alloc(T, width * height),
                .width = width,
                .height = height,
            };
        }
        pub fn initWithDefault(allocator: Allocator, width: usize, height: usize, default: T) !Self {
            const result = try init(allocator, width, height);
            @memset(result.data, default);
            return result;
        }

        pub fn deinit(self: Self, allocator: Allocator) void {
            allocator.free(self.data);
        }

        pub inline fn set(self: Self, x: usize, y: usize, value: T) void {
            std.debug.assert(x >= 0);
            std.debug.assert(y >= 0);
            std.debug.assert(x < self.width);
            std.debug.assert(y < self.height);
            self.data[y * self.width + x] = value;
        }
        pub inline fn get(self: Self, x: usize, y: usize) T {
            std.debug.assert(x >= 0);
            std.debug.assert(y >= 0);
            std.debug.assert(x < self.width);
            std.debug.assert(y < self.height);
            return self.data[y * self.width + x];
        }
        pub inline fn getPtr(self: Self, x: usize, y: usize) *T {
            std.debug.assert(x >= 0);
            std.debug.assert(y >= 0);
            std.debug.assert(x < self.width);
            std.debug.assert(y < self.height);
            return &self.data[y * self.width + x];
        }

        pub fn format(value: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = options;
            for (0..value.height) |y| {
                for (0..value.width) |x| {
                    try writer.print("{" ++ fmt ++ "}", .{value.get(x, y).mask});
                }
                try writer.writeByte('\n');
            }
        }
    };
}
