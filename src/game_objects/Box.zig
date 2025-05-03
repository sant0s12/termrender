const Box = @This();
const TermBuffer = @import("../TermBuffer.zig");
const std = @import("std");

termBuffer: *TermBuffer,
x: f32 = 0,
y: f32 = 0,

vx: f32 = 0,
vy: f32 = 0,

ax: f32 = 0,
ay: f32 = 0,

gravity: f32 = 0.05,
friction: f32 = 0.95,

pub fn draw(self: *Box) void {
    self.termBuffer.drawSingle('x', @intFromFloat(self.x), @intFromFloat(self.y)) catch return;
}

