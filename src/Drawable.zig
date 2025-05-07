const assert = @import("std").debug.assert;
const t = @import("std").builtin.Type;
const Drawable = @This();
const Vec2f = @import("math.zig").Vec2f;

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    draw: *const fn (*anyopaque) void,
    tick: *const fn (*anyopaque) Vec2f,
    position: *const fn (*anyopaque) *Vec2f,
    speed: *const fn (*anyopaque) *Vec2f,
    intersect: *const fn (*anyopaque, Vec2f) bool,
};

pub fn draw(self: Drawable) void {
    return self.vtable.draw(self.ptr);
}

pub fn tick(self: Drawable) Vec2f {
    return self.vtable.tick(self.ptr);
}

pub fn position(self: Drawable) *Vec2f {
    return self.vtable.position(self.ptr);
}

pub fn speed(self: Drawable) *Vec2f {
    return self.vtable.speed(self.ptr);
}

pub fn intersect(self: Drawable, pos: Vec2f) bool {
    return self.vtable.intersect(self.ptr, pos);
}

// https://zig.news/yglcode/code-study-interface-idiomspatterns-in-zig-standard-libraries-4lkj
pub fn init(pointer: anytype) Drawable {
    const Ptr = @TypeOf(pointer);
    assert(@typeInfo(Ptr) == .pointer);
    assert(@typeInfo(Ptr).pointer.size == .one);
    assert(@typeInfo(@typeInfo(Ptr).pointer.child) == .@"struct");

    const impl = struct {
        fn draw(ptr: *anyopaque) void {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            self.draw();
        }

        fn tick(ptr: *anyopaque) Vec2f {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return self.tick();
        }

        fn position(ptr: *anyopaque) *Vec2f  {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return &self.position;
        }

        fn speed(ptr: *anyopaque) *Vec2f  {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return &self.speed;
        }

        fn intersect(ptr: *anyopaque, pos: Vec2f) bool {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return self.intersect(pos);
        }
    };

    return .{
        .ptr = pointer,
        .vtable = &.{ .draw = impl.draw, .tick = impl.tick, .position = impl.position, .speed = impl.speed, .intersect = impl.intersect },
    };
}
