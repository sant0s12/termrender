const Player = @This();
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

pub fn draw(self: *Player) void {
    self.termBuffer.drawSingle('x', @intFromFloat(self.x), @intFromFloat(self.y)) catch return;
}

pub fn tick(self: *Player) void {
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

pub fn intersect(self: *Player, x: f32, y: f32) bool {
    return @round(self.x) == @round(x) and @round(self.y) == @round(y);
}
