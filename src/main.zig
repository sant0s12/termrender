const std = @import("std");
const lib = @import("lib.zig");
const assert = @import("std").debug.assert;

const TermBuffer = struct {
    allocator: *const std.mem.Allocator,
    writer: *const std.io.AnyWriter,
    rows: usize = 0,
    cols: usize = 0,

    fn init(allocator: *const std.mem.Allocator, writer: *const std.io.AnyWriter) !TermBuffer {
        var self = TermBuffer{
            .allocator = allocator,
            .writer = writer,
        };

        try self.updateSize();

        return self;
    }

    fn deinit(self: *TermBuffer) !void {
        _ = self;
    }

    fn updateSize(self: *TermBuffer) !void {
        const termSize = try lib.getTermSize();
        if (termSize.cols == self.cols and termSize.rows == self.rows) {
            return;
        } else {
            self.rows = termSize.rows;
            self.cols = termSize.cols;
        }
    }

    fn clearTerm(self: *TermBuffer) !void {
        const code = "\x1B[2J\x1B[H";
        _ = try self.writer.write(code);
    }

    fn drawSingle(self: *TermBuffer, char: u8, x: usize, y: usize) !void {
        _ = try self.writer.print("\x1B[{};{}f{c}", .{ y + 1, x + 1, char });
    }
};

const BouncyX = struct {
    termBuffer: *TermBuffer,
    x: usize = 0,
    y: usize = 0,

    vx: isize = 0,
    vy: isize = 0,

    fn draw(self: *BouncyX) !void {
        try self.termBuffer.drawSingle('x', self.x, self.y);
    }

    fn tick(self: *BouncyX) void {
        // Clamp in case window is resized
        self.x = std.math.clamp(self.x, 0, self.termBuffer.cols - 1);
        self.y = std.math.clamp(self.y, 0, self.termBuffer.rows - 1);

        // Bounce
        if (self.x == self.termBuffer.cols - 1 or self.x == 0) {
            self.vx = -self.vx;
        }

        if (self.y == self.termBuffer.rows - 1 or self.y == 0) {
            self.vy = -self.vy;
        }

        // Move
        var uvx: usize = @intCast(@abs(self.vx));
        var uvy: usize = @intCast(@abs(self.vy));

        if (self.vx < 0) {
            uvx = @min(uvx, self.x);
        } else {
            uvx = @min(uvx, self.termBuffer.cols - self.x - 1);
        }

        if (self.vy < 0) {
            uvy = @min(uvy, self.y);
        } else {
            uvy = @min(uvy, self.termBuffer.rows - self.y - 1);
        }

        self.x = if (self.vx < 0) self.x - uvx else self.x + uvx;
        self.y = if (self.vy < 0) self.y - uvy else self.y + uvy;
    }
};

pub fn main() !void {
    const writer = std.io.getStdOut().writer().any();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var buffer: TermBuffer = try TermBuffer.init(&allocator, &writer);

    var bouncyX = BouncyX{ .vx = 1, .vy = 1, .termBuffer = &buffer };

    while (true) {
        _ = try buffer.updateSize();
        _ = try buffer.clearTerm();
        // _ = buffer.clearBuffer();

        // Draw stuff
        bouncyX.tick();
        try bouncyX.draw();

        // _ = try buffer.draw();

        std.time.sleep(10 * std.time.ns_per_ms);
    }
}
