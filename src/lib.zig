//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

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
