const assert = @import("std").debug.assert;
const Drawable = @This();

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    draw: *const fn (*anyopaque) void,
    tick: *const fn (*anyopaque) void,
};

pub fn draw(self: Drawable) void {
    return self.vtable.draw(self.ptr);
}

pub fn tick(self: Drawable) void {
    return self.vtable.tick(self.ptr);
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
    };

    return .{
        .ptr = pointer,
        .vtable = &.{ .draw = impl.draw, .tick = impl.tick },
    };
}
