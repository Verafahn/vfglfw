const std = @import("std");
const Image = @This();

width: u32,
height: u32,
pixels: []const u8,

/// Checks that the pixel buffer contains at least `width * height * 4` bytes
/// of RGBA data, as required by GLFW.
pub fn validate(self: Image) error{InvalidValue}!void {
    if (self.width == 0 or self.height == 0) return error.InvalidValue;
    if (self.width > std.math.maxInt(i32) or self.height > std.math.maxInt(i32))
        return error.InvalidValue;

    const pixel_count = std.math.mul(usize, self.width, self.height) catch
        return error.InvalidValue;
    const byte_count = std.math.mul(usize, pixel_count, 4) catch
        return error.InvalidValue;

    if (self.pixels.len < byte_count) return error.InvalidValue;
}
