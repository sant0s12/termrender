const Player = @This();
const TermBuffer = @import("../TermBuffer.zig");
const std = @import("std");
const Vec2f = @import("../math.zig").Vec2f;

termBuffer: *TermBuffer,

position: Vec2f = .{0, 0},
speed: Vec2f = .{0, 0},
acceleration: Vec2f = .{0, 0},

gravity: f32 = 0.05,
friction: f32 = 0.95,

pub fn draw(self: *Player) void {
    self.termBuffer.drawSingle('x', @intFromFloat(self.position[0]), @intFromFloat(self.position[1])) catch return;
}

pub fn tick(self: *Player) Vec2f {
    // Acceleration
    self.speed += self.acceleration;
    self.speed[1] += self.gravity;

    // std.debug.print("{}", .{self.speed});

    // Friction
    self.speed[0] *= self.friction;

    return self.speed;
}

pub fn intersect(self: *Player, point: Vec2f) bool {
    return @round(self.position[0]) == @round(point[0]) and @round(self.position[1]) == @round(point[1]);
}
