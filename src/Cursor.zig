const glfw = @import("glfw3");
const Image = @import("Image.zig");
const Cursor = @This();

impl: *glfw.Cursor,

pub fn create(image: *const Image, xhot: i32, yhot: i32) error{InvalidValue}!Cursor {
    const img = glfw.Image{
        .width = @intCast(image.width),
        .height = @intCast(image.height),
        .pixels = @ptrCast(image.pixels),
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

pub const StandrandCursor = enum(c_int) {
    ARROW = glfw.ARROW_CURSOR,
    IBEAM = glfw.IBEAM_CURSOR,
    CROSSHAIR = glfw.CROSSHAIR_CURSOR,
    // POINTING_HAND = glfw.POINTING_HAND_CURSOR,
    // RESIZE_EW = glfw.RESIZE_EW_CURSOR,
    // RESIZE_NS = glfw.RESIZE_NS_CURSOR,
    RESIZE_NWSE = glfw.RESIZE_NWSE_CURSOR,
    RESIZE_NESW = glfw.RESIZE_NESW_CURSOR,
    RESIZE_ALL = glfw.RESIZE_ALL_CURSOR,
    NOT_ALLOWED = glfw.NOT_ALLOWED_CURSOR,
    HRESIZE = glfw.HRESIZE_CURSOR,
    VRESIZE = glfw.VRESIZE_CURSOR,
    HAND = glfw.HAND_CURSOR,
};

pub fn createStandrad(cursor: StandrandCursor) error{CursorUnavailable}!Cursor {
    const cur = glfw.createStandardCursor(@intFromEnum(cursor));
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
