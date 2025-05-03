const TermBuffer = @This();
const std = @import("std");
const term = @import("term.zig");

writer: *const std.io.AnyWriter,
rows: usize = 0,
cols: usize = 0,

pub fn init(writer: *const std.io.AnyWriter) !TermBuffer {
    var self = TermBuffer{
        .writer = writer,
    };

    try self.updateSize();

    return self;
}

pub fn deinit(self: *TermBuffer) !void {
    _ = self;
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
    _ = try self.writer.print("\x1B[{};{}f{c}", .{ y + 1, x + 1, char });
}
