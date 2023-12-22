const std = @import("std");
const Allocator = std.mem.Allocator;

/// A thin wrapper around a 3D array
pub fn Array3D(comptime T: type) type {
    return struct {
        const Self = @This();

        data: []T,
        width: usize,
        height: usize,
        depth: usize,

        pub fn init(allocator: Allocator, width: usize, height: usize, depth: usize) !Self {
            return .{
                .data = try allocator.alloc(T, width * height * depth),
                .width = width,
                .height = height,
                .depth = depth,
            };
        }
        pub fn initWithDefault(allocator: Allocator, width: usize, height: usize, depth: usize, default: T) !Self {
            const result = try init(allocator, width, height, depth);
            @memset(result.data, default);
            return result;
        }

        pub fn deinit(self: Self, allocator: Allocator) void {
            allocator.free(self.data);
        }

        pub inline fn set(self: Self, x: usize, y: usize, z: usize, value: T) void {
            std.debug.assert(x >= 0);
            std.debug.assert(y >= 0);
            std.debug.assert(z >= 0);
            std.debug.assert(x < self.width);
            std.debug.assert(y < self.height);
            std.debug.assert(z < self.depth);
            self.data[z * self.width * self.height + y * self.width + x] = value;
        }
        pub inline fn get(self: Self, x: usize, y: usize, z: usize) T {
            std.debug.assert(x >= 0);
            std.debug.assert(y >= 0);
            std.debug.assert(z >= 0);
            std.debug.assert(x < self.width);
            std.debug.assert(y < self.height);
            std.debug.assert(z < self.depth);
            return self.data[z * self.width * self.height + y * self.width + x];
        }
        pub inline fn getPtr(self: Self, x: usize, y: usize, z: usize) *T {
            std.debug.assert(x >= 0);
            std.debug.assert(y >= 0);
            std.debug.assert(z >= 0);
            std.debug.assert(x < self.width);
            std.debug.assert(y < self.height);
            std.debug.assert(z < self.depth);
            return &self.data[z * self.width * self.height + y * self.width + x];
        }

        pub fn format(value: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = options;
            const idx = comptime std.mem.indexOfScalar(u8, fmt, ':');
            const z = comptime try std.fmt.parseInt(usize, fmt[0..idx], 10);

            for (0..value.height) |y| {
                for (0..value.width) |x| {
                    if (value.get(x, y) == 0) {
                        try writer.print(" ", .{});
                    } else {
                        try writer.print("{" ++ fmt ++ "}", .{value.get(x, y, z)});
                    }
                }
                try writer.writeByte('\n');
            }
        }
    };
}
