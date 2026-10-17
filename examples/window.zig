const std = @import("std");
const glfw = @import("vfglfw");

pub fn main(init: std.process.Init) !void {
    // Replace GLFW default allocator with `init.gpa`.
    try glfw.init(init.gpa, .{});
    defer glfw.deinit();

    var window = try glfw.Window.create(1600, 900, "expample_window", .{});
    defer window.destroy();

    // Event loop.
    while (!window.shouldClose()) {
        window.swapBuffer();
        glfw.event.poll();
    }
}
