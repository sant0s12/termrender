const std = @import("std");

const TermBuffer = @import("../TermBuffer.zig");
const Vec2f = @import("../math.zig").Vec2f;
const BBox = @import("../BBox.zig");
const Drawable = @import("../Drawable.zig");

const Player = @This();

termBuffer: *TermBuffer,

// In object coordinates
bbox: BBox = .{},

position: Vec2f = .{ 0, 0 },
speed: Vec2f = .{ 0, 0 },
acceleration: Vec2f = .{ 0, 0 },

gravity: f32 = 0.05,
friction: f32 = 0.95,

pub fn init(termBuffer: *TermBuffer, position: Vec2f) Player {
    return Player{
        .termBuffer = termBuffer,
        .position = position,
        .bbox = BBox{
            .top_left = position,
            .bottom_right = position,
        },
    };
}

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

pub fn intersect(self: *Player, other: *const Drawable) ?BBox {
    _ = self;
    _ = other;
    return null;
}
