const assert = @import("std").debug.assert;
const t = @import("std").builtin.Type;
const Drawable = @This();

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    draw: *const fn (*anyopaque) void,
    tick: *const fn (*anyopaque) void,
    position: *const fn (*anyopaque) struct { *f32, *f32 },
    speed: *const fn (*anyopaque) struct { *f32, *f32 },
    intersect: *const fn (*anyopaque, f32, f32) bool,
};

pub fn draw(self: Drawable) void {
    return self.vtable.draw(self.ptr);
}

pub fn tick(self: Drawable) void {
    return self.vtable.tick(self.ptr);
}

pub fn position(self: Drawable) struct { *f32, *f32 } {
    return self.vtable.position(self.ptr);
}

pub fn speed(self: Drawable) struct { *f32, *f32 } {
    return self.vtable.speed(self.ptr);
}

pub fn intersect(self: Drawable, x: f32, y: f32) bool {
    return self.vtable.intersect(self.ptr, x, y);
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

        fn tick(ptr: *anyopaque) void {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            self.tick();
        }

        fn position(ptr: *anyopaque) struct { *f32, *f32 } {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return .{ &self.x, &self.y };
        }

        fn speed(ptr: *anyopaque) struct { *f32, *f32 } {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return .{ &self.vx, &self.vy };
        }

        fn intersect(ptr: *anyopaque, x: f32, y: f32) bool {
            const self: Ptr = @ptrCast(@alignCast(ptr));
            return self.intersect(x, y);
        }
    };

    return .{
        .ptr = pointer,
        .vtable = &.{ .draw = impl.draw, .tick = impl.tick, .position = impl.position, .speed = impl.speed, .intersect = impl.intersect },
    };
}
