const std = @import("std");
const lib = @import("lib.zig");
const assert = @import("std").debug.assert;

var cooked_termios: std.os.linux.termios = undefined;

const stdout = std.io.getStdOut().writer().any();
const stdin = std.io.getStdIn().reader();

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

fn uncookTerm() void {
    // Save term attrs to restore later
    if (std.os.linux.tcgetattr(0, &cooked_termios) < 0) {
        std.io.getStdErr().writer().print("Could not read term settings :(\n");
        std.os.exit(1);
    }

    var uncooked_termios: std.os.linux.termios = cooked_termios;

    // https://www.reddit.com/r/Zig/comments/b0dyfe/polling_for_key_presses/
    // Input
    uncooked_termios.iflag.BRKINT = false;
    uncooked_termios.iflag.ICRNL = false;
    uncooked_termios.iflag.INPCK = false;
    uncooked_termios.iflag.ISTRIP = false;
    uncooked_termios.iflag.IXON = false;

    // Output
    uncooked_termios.lflag.ECHO = false;
    uncooked_termios.lflag.ICANON = false;
    uncooked_termios.lflag.ISIG = false;

    // Non-blocking reads
    uncooked_termios.cc[@intFromEnum(std.os.linux.V.MIN)] = 0;
    uncooked_termios.cc[@intFromEnum(std.os.linux.V.TIME)] = 0;

    if (std.os.linux.tcsetattr(0, std.os.linux.TCSA.NOW, &uncooked_termios) < 0) {
        std.io.getStdErr().writer().print("Could not uncook term :(\n");
        std.os.exit(1);
    }
}

fn cookTerm() void {
    if (std.os.linux.tcsetattr(0, std.os.linux.TCSA.NOW, &cooked_termios) < 0) {
        std.io.getStdErr().writer().print("Could not cook term :(\n");
        std.os.exit(1);
    }
}

fn hideCursor(writer: *const std.io.AnyWriter) !void {
    _ = try writer.write("\x1B[?25l");
}

fn showCursor(writer: *const std.io.AnyWriter) !void {
    _ = try writer.write("\x1B[?25h");
}

pub fn main() !void {
    uncookTerm();
    defer cookTerm();

    try hideCursor(&stdout);
    defer showCursor(&stdout) catch unreachable;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var buffer: TermBuffer = try TermBuffer.init(&allocator, &stdout);

    var bouncy_x = BouncyX{ .vx = 1, .vy = 1, .termBuffer = &buffer };

    var read_buff: [1]u8 = undefined;
    while (true) {
        // Read input
        if (try stdin.read(&read_buff) > 0) {
            switch (read_buff[0]) {
                'x' => bouncy_x.vx += 1,
                'y' => bouncy_x.vy += 1,
                'q' => break,
                else => {},
            }

            read_buff[0] = 0x0;
        }

        try buffer.updateSize();
        try buffer.clearTerm();
        // _ = buffer.clearBuffer();

        // Draw stuff
        bouncy_x.tick();
        try bouncy_x.draw();

        // _ = try buffer.draw();

        std.time.sleep(10 * std.time.ns_per_ms);
    }

    try buffer.clearTerm();
}
