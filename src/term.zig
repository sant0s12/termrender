const std = @import("std");

var cooked_termios: std.os.linux.termios = undefined;

pub const TermSize = struct { rows: usize, cols: usize };

pub const TermError = error{IoctlFail};

pub fn getTermSize() TermError!TermSize {
    var winsize: std.posix.winsize = undefined;
    const termFd = std.io.getStdOut().handle;

    const err = std.posix.system.ioctl(termFd, std.posix.T.IOCGWINSZ, @intFromPtr(&winsize));
    if (std.posix.errno(err) == .SUCCESS) {
        return TermSize{ .rows = winsize.row, .cols = winsize.col };
    } else {
        return TermError.IoctlFail;
    }
}

pub fn uncookTerm() void {
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

pub fn cookTerm() void {
    if (std.os.linux.tcsetattr(0, std.os.linux.TCSA.NOW, &cooked_termios) < 0) {
        std.io.getStdErr().writer().print("Could not cook term :(\n");
        std.os.exit(1);
    }
}

pub fn hideCursor(writer: *const std.io.AnyWriter) !void {
    _ = try writer.write("\x1B[?25l");
}

pub fn showCursor(writer: *const std.io.AnyWriter) !void {
    _ = try writer.write("\x1B[?25h");
}
