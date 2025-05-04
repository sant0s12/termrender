const Player = @This();
const TermBuffer = @import("../TermBuffer.zig");
const std = @import("std");
const Vec2D = @import("../math.zig").Vec2D;

termBuffer: *TermBuffer,

position: Vec2D(f32) = .{},
speed: Vec2D(f32) = .{},
acceleration: Vec2D(f32) = .{},

gravity: f32 = 0.05,
friction: f32 = 0.95,

pub fn draw(self: *Player) void {
    self.termBuffer.drawSingle('x', @intFromFloat(self.position.x), @intFromFloat(self.position.y)) catch return;
}

pub fn tick(self: *Player) Vec2D(f32) {
    const buffer_cols = @as(f32, @floatFromInt(self.termBuffer.cols - 1));
    const buffer_rows = @as(f32, @floatFromInt(self.termBuffer.rows - 1));

    var retval = Vec2D(f32){};

    // Acceleration
    self.speed.plusEq(self.acceleration);
    self.speed.y += self.acceleration.y + self.gravity;

    // Friction
    self.speed.x *= self.friction;

    // Clamp in case window is resized
    retval.x = std.math.clamp(self.position.x, 0, buffer_cols);
    retval.y = std.math.clamp(self.position.y, 0, buffer_rows);

    // Stop at wall
    if (self.speed.x > 0 and retval.x == buffer_cols or self.speed.x < 0 and retval.x == 0) {
        self.speed.x = 0;
    }

    if (self.speed.y > 0 and retval.y == buffer_rows or self.speed.y < 0 and retval.y == 0) {
        self.speed.y = 0;
    }

    // Move
    var uvx: f32 = @abs(self.speed.x);
    var uvy: f32 = @abs(self.speed.y);

    if (self.speed.x < 0) {
        uvx = @min(uvx, retval.x);
    } else {
        uvx = @min(uvx, buffer_cols - retval.x);
    }

    if (self.speed.y < 0) {
        uvy = @min(uvy, retval.y);
    } else {
        uvy = @min(uvy, buffer_rows - retval.y);
    }

    retval.x = if (self.speed.x < 0) retval.x - uvx else retval.x + uvx;
    retval.y = if (self.speed.y < 0) retval.y - uvy else retval.y + uvy;

    return retval;
}

pub fn intersect(self: *Player, point: Vec2D(f32)) bool {
    return @round(self.position.x) == @round(point.x) and @round(self.position.y) == @round(point.y);
}
