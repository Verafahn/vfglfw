const glfw = @import("glfw3");
const Image = @import("Image.zig");
const Cursor = @This();

impl: *glfw.Cursor,

pub fn create(image: Image, xhot: i32, yhot: i32) error{InvalidValue}!Cursor {
    try image.validate();
    const img = glfw.Image{
        .width = @intCast(image.width),
        .height = @intCast(image.height),
        .pixels = @ptrCast(@constCast(image.pixels.ptr)),
    };
    const cursor = glfw.createCursor(
        &img,
        @intCast(xhot),
        @intCast(yhot),
    );
    if (cursor == null) {
        @branchHint(.cold);
        glfw.check() catch |err| switch (err) {
            error.InvalidValue => return @errorCast(err),
            else => unreachable,
        };
        unreachable;
    }
    return .{ .impl = cursor.? };
}

pub const StandardCursor = enum(c_int) {
    arrow = glfw.ARROW_CURSOR,
    ibeam = glfw.IBEAM_CURSOR,
    crosshair = glfw.CROSSHAIR_CURSOR,
    pointing_hand = glfw.POINTING_HAND_CURSOR,
    resize_ew = glfw.RESIZE_EW_CURSOR,
    resize_ns = glfw.RESIZE_NS_CURSOR,
    resize_nwse = glfw.RESIZE_NWSE_CURSOR,
    resize_nesw = glfw.RESIZE_NESW_CURSOR,
    resize_all = glfw.RESIZE_ALL_CURSOR,
    not_allowed = glfw.NOT_ALLOWED_CURSOR,
};

pub fn createStandard(cursor: StandardCursor) error{CursorUnavailable}!Cursor {
    const cur = glfw.createStandardCursor(@backingInt(cursor));
    if (cur == null) {
        @branchHint(.cold);
        glfw.check() catch |err| switch (err) {
            error.CursorUnavailable => return @errorCast(err),
            else => unreachable,
        };
        unreachable;
    }
    return .{ .impl = cur.? };
}

pub fn destroy(self: Cursor) void {
    glfw.destroyCursor(self.impl);
}
