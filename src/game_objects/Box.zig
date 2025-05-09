const std = @import("std");

const TermBuffer = @import("../TermBuffer.zig");
const Vec2f = @import("../math.zig").Vec2f;
const BBox = @import("../BBox.zig");
const Drawable = @import("../Drawable.zig");

const Box = @This();

termBuffer: *TermBuffer,

speed: Vec2f = .{ 0, 0 },
acceleration: Vec2f = .{ 0, 0 },
position: Vec2f = .{ 0, 0 },

gravity: f32 = 0.01,
friction: f32 = 0.95,

bbox: BBox = .{},

pub fn init(termBuffer: *TermBuffer, position: Vec2f, height: f32, width: f32) Box {
    return Box{
        .termBuffer = termBuffer,
        .position = position,
        .bbox = BBox{
            .top_left = Vec2f{ 0, 0 },
            .bottom_right = Vec2f{ width, height },
        },
    };
}

pub fn draw(self: *Box) void {
    const width, const height = @as(@Vector(2, usize), @intFromFloat(self.bbox.bottom_right - self.bbox.top_left));

    var i: usize = 0;
    while (i < height) : (i += 1) {

        var j: usize = 0;
        while (j < width) : (j += 1) {
            const offset = @as(@Vector(2, usize), @intFromFloat(self.position)) + @Vector(2, usize){ j, i };

            const x, const y = offset;
            self.termBuffer.drawSingle('.', x, y) catch return;
        }
    }
}

pub fn tick(self: *Box) Vec2f {
    // Acceleration
    self.speed += self.acceleration;
    self.speed[1] += self.acceleration[1] + self.gravity;

    // Friction
    self.speed[0] *= self.friction;

    return self.speed;
}

pub fn intersect(self: *Box, other: *const Drawable) ?BBox {
    _ = self;
    _ = other;
    return null;
}
