const std = @import("std");

pub fn scan(comptime fmt: []const u8, buffer: []const u8) !ScanTuple(fmt) {
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
