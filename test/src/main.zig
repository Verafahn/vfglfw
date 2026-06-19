const std = @import("std");
const glfw = @import("zglfw");
const gl = @import("zgl");

fn loadGL(_: @TypeOf(undefined), name: [:0]const u8) ?*align(1) const anyopaque {
    return @ptrCast(@alignCast(glfw.getProcAddress(name)));
}

pub fn main(init: std.process.Init) !void {
    try glfw.init(init.gpa, .{});
    defer glfw.deinit();

    var window = try glfw.Window.create(1600, 900, "Demo", .{});
    defer window.destroy();

    window.makeContextCurrent();
    try gl.loadExtensions(undefined, loadGL);

    gl.viewport(0, 0, 1600, 900);

    while (!window.shouldClose()) {
        window.swapBuffer();

        gl.clear(.{ .color = true });
        gl.clearColor(0.5, 0.7, 0.9, 1.0);

        glfw.event.poll();
    }
}
