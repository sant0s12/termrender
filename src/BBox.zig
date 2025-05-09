const Vec2f = @import("math.zig").Vec2f;
const TermBuffer = @import("TermBuffer.zig");

const BBox = @This();

top_left: Vec2f = .{ 0, 0 },
bottom_right: Vec2f = .{ 0, 0 },

pub fn toWorld(self: *const BBox, position: *const Vec2f) BBox {
    return BBox{
        .top_left = self.top_left + position.*,
        .bottom_right = self.bottom_right + position.*,
    };
}

pub fn toLocal(self: *const BBox, position: *const Vec2f) BBox {
    return BBox{
        .top_left = self.top_left - position.*,
        .bottom_right = self.bottom_right - position.*,
    };
}

pub fn draw(self: *const BBox, termBuffer: *TermBuffer) void {
    // Draw vertical lines
    for (@intFromFloat(self.top_left[0])..@intFromFloat(self.bottom_right[0])) |x| {
        termBuffer.drawSingle('-', x, @intFromFloat(self.top_left[1])) catch return;
        termBuffer.drawSingle('-', x, @intFromFloat(self.bottom_right[1])) catch return;
    }

    // Draw horizontal lines
    for (@intFromFloat(self.top_left[1])..@intFromFloat(self.bottom_right[1])) |y| {
        termBuffer.drawSingle('|', @intFromFloat(self.top_left[0]), y) catch return;
        termBuffer.drawSingle('|', @intFromFloat(self.bottom_right[0]), y) catch return;
    }
}

pub fn intersect(self: *const BBox, other: *const BBox) ?BBox {
    if (other.top_left[0] > self.bottom_right[0] or other.bottom_right[0] < self.top_left[0] or other.top_left[1] > self.bottom_right[1] or other.bottom_right[1] < self.top_left[1]) return null;

    return BBox{
        .top_left = Vec2f{
            @max(self.top_left[0], other.top_left[0]),
            @max(self.top_left[1], other.top_left[1]),
        },
        .bottom_right = Vec2f{
            @min(self.bottom_right[0], other.bottom_right[0]),
            @min(self.bottom_right[1], other.bottom_right[1]),
        },
    };
}
