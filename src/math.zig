pub fn Vec2D(T: type) type {
    return struct {
        const Self = @This();

        x: T = 0,
        y: T = 0,

        pub fn plus(self: Self, other: Self) Self {
            return Self{ .x = self.x + other.x, .y = self.y + other.y };
        }

        pub fn plusEq(self: *Self, other: Self) void {
            self.x += other.x;
            self.y += other.y;
        }
    };
}
