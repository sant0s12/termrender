const TermBuffer = @This();
const std = @import("std");
const term = @import("term.zig");

writer: *const std.io.AnyWriter,
rows: usize = 0,
cols: usize = 0,
// Buffer to accumulate ANSI sequences before writing
write_buffer: std.ArrayList(u8) = undefined,
allocator: std.mem.Allocator = undefined,

pub fn init(writer: *const std.io.AnyWriter, allocator: std.mem.Allocator) !TermBuffer {
    var self = TermBuffer{
        .writer = writer,
        .allocator = allocator,
        .write_buffer = std.ArrayList(u8).init(allocator),
    };

    try self.updateSize();

    return self;
}

pub fn deinit(self: *TermBuffer) void {
    self.write_buffer.deinit();
}

pub fn updateSize(self: *TermBuffer) !void {
    const termSize = try term.getTermSize();
    if (termSize.cols == self.cols and termSize.rows == self.rows) {
        return;
    } else {
        self.rows = termSize.rows;
        self.cols = termSize.cols;
    }
}

pub fn clearTerm(self: *TermBuffer) !void {
    const code = "\x1B[2J\x1B[H";
    _ = try self.writer.write(code);
}

pub fn drawSingle(self: *TermBuffer, char: u8, x: usize, y: usize) !void {
    // Append to buffer instead of immediately writing
    try self.write_buffer.writer().print("\x1B[{};{}f{c}", .{ y + 1, x + 1, char });
}

// Flush the accumulated buffer to the terminal
pub fn flush(self: *TermBuffer) !void {
    if (self.write_buffer.items.len > 0) {
        _ = try self.writer.write(self.write_buffer.items);
        self.write_buffer.clearRetainingCapacity();
    }
}
