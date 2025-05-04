const assert = @import("std").debug.assert;
const t = @import("std").builtin.Type;
const Drawable = @This();
const Vec2D = @import("math.zig").Vec2D;

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    draw: *const fn (*anyopaque) void,
    tick: *const fn (*anyopaque) Vec2D(f32),
    position: *const fn (*anyopaque) *Vec2D(f32),
    speed: *const fn (*anyopaque) *Vec2D(f32),
    intersect: *const fn (*anyopaque, Vec2D(f32)) bool,
};

pub fn draw(self: Drawable) void {
    return self.vtable.draw(self.ptr);
}

pub fn tick(self: Drawable) Vec2D(f32) {
    return self.vtable.tick(self.ptr);
}

pub fn position(self: Drawable) *Vec2D(f32) {
    return self.vtable.position(self.ptr);
}

pub fn speed(self: Drawable) *Vec2D(f32) {
    return self.vtable.speed(self.ptr);
}

pub fn intersect(self: Drawable, pos: Vec2D(f32)) bool {
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

        fn tick(ptr: *anyopaque) Vec2D(f32) {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return self.tick();
        }

        fn position(ptr: *anyopaque) *Vec2D(f32)  {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return &self.position;
        }

        fn speed(ptr: *anyopaque) *Vec2D(f32)  {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return &self.speed;
        }

        fn intersect(ptr: *anyopaque, pos: Vec2D(f32)) bool {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return self.intersect(pos);
        }
    };

    return .{
        .ptr = pointer,
        .vtable = &.{ .draw = impl.draw, .tick = impl.tick, .position = impl.position, .speed = impl.speed, .intersect = impl.intersect },
    };
}
