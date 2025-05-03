const std = @import("std");
const term = @import("term.zig");
const Drawable = @import("Drawable.zig");

const assert = @import("std").debug.assert;

const stdout = std.io.getStdOut().writer().any();
const stdin = std.io.getStdIn().reader();

const INTENSITY: []u8 = " .,-~:;=!*#$@";
const MAX_INTENSITY = INTENSITY.len;
const MIN_INTENSITY = 0;

const TermBuffer = struct {
    writer: *const std.io.AnyWriter,
    rows: usize = 0,
    cols: usize = 0,

    fn init(writer: *const std.io.AnyWriter) !TermBuffer {
        var self = TermBuffer{
            .writer = writer,
        };

        try self.updateSize();

        return self;
    }

    fn deinit(self: *TermBuffer) !void {
        _ = self;
    }

    fn updateSize(self: *TermBuffer) !void {
        const termSize = try term.getTermSize();
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
    x: f32 = 0,
    y: f32 = 0,

    vx: f32 = 0,
    vy: f32 = 0,

    ax: f32 = 0,
    ay: f32 = 0,

    gravity: f32 = 0.05,
    friction: f32 = 0.95,

    pub fn draw(self: *BouncyX) void {
        self.termBuffer.drawSingle('x', @intFromFloat(self.x), @intFromFloat(self.y)) catch return;
    }

    pub fn tick(self: *BouncyX) void {
        const buffer_cols = @as(f32, @floatFromInt(self.termBuffer.cols - 1));
        const buffer_rows = @as(f32, @floatFromInt(self.termBuffer.rows - 1));

        // Acceleration
        self.vx += self.ax;
        self.vy += self.ay + self.gravity;

        // Friction
        self.vx *= self.friction;

        // Clamp in case window is resized
        self.x = std.math.clamp(self.x, 0, buffer_cols);
        self.y = std.math.clamp(self.y, 0, buffer_rows);

        // Stop at wall
        if (self.vx > 0 and self.x == buffer_cols or self.vx < 0 and self.x == 0) {
            self.vx = 0;
        }

        if (self.vy > 0 and self.y == buffer_rows or self.vy < 0 and self.y == 0) {
            self.vy = 0;
        }

        // Move
        var uvx: f32 = @abs(self.vx);
        var uvy: f32 = @abs(self.vy);

        if (self.vx < 0) {
            uvx = @min(uvx, self.x);
        } else {
            uvx = @min(uvx, buffer_cols - self.x);
        }

        if (self.vy < 0) {
            uvy = @min(uvy, self.y);
        } else {
            uvy = @min(uvy, buffer_rows - self.y);
        }

        self.x = if (self.vx < 0) self.x - uvx else self.x + uvx;
        self.y = if (self.vy < 0) self.y - uvy else self.y + uvy;
    }
};

pub fn main() !void {
    term.uncookTerm();
    defer term.cookTerm();

    try term.hideCursor(&stdout);
    defer term.showCursor(&stdout) catch unreachable;

    var buffer: TermBuffer = try TermBuffer.init(&stdout);

    var bouncy_x = BouncyX{ .vx = 0, .vy = 0, .termBuffer = &buffer };
    var bouncy_drawable = Drawable.init(&bouncy_x);

    var read_buff: [3]u8 = undefined;
    while (true) {
        // Read input
        if (try stdin.read(&read_buff) > 0) {
            switch (read_buff[0]) {
                'a' => bouncy_x.vx -= 0.5,
                's' => bouncy_x.vy += 0.5,
                'd' => bouncy_x.vx += 0.5,
                ' ' => bouncy_x.vy -= 1.5,
                'q' => break,
                else => {},
            }

            @memset(&read_buff, 0);
        }

        try buffer.updateSize();
        try buffer.clearTerm();

        // // Draw stuff
        bouncy_drawable.tick();
        bouncy_drawable.draw();

        std.time.sleep(10 * std.time.ns_per_ms);
    }

    try buffer.clearTerm();
}
