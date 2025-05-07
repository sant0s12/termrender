const Box = @This();
const TermBuffer = @import("../TermBuffer.zig");
const std = @import("std");
const Vec2f = @import("../math.zig").Vec2f;

termBuffer: *TermBuffer,
position: Vec2f = .{},
speed: Vec2f = .{},
acceleration: Vec2f = .{},

gravity: f32 = 0.05,
friction: f32 = 0.95,

pub fn draw(self: *Box) void {
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        var j: usize = 0;
        while (j < 3) : (j += 1) {
            const x: usize = @as(usize, @intFromFloat(self.x)) + j;
            const y: usize = @as(usize, @intFromFloat(self.y)) + i;

            self.termBuffer.drawSingle('.', x, y) catch return;
        }
    }
}

pub fn tick(self: *Box) Vec2f {
    // Acceleration
    self.speed += self.acceleration;
    self.speed.y += self.acceleration.y + self.gravity;

    // Friction
    self.speed.x *= self.friction;

    return self.speed;
}

pub fn intersect(self: *Box, x: f32, y: f32) bool {
    _ = self;
    _ = x;
    _ = y;
    return false;
}
