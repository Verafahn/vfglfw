const std = @import("std");
const glfw = @import("vfglfw");
const glad = @import("glad");
const Event = glfw.Handle.Event;

pub const MyWindow = struct {
    pub fn handle(self: *MyWindow) glfw.Handle {
        return .{
            .vptr = self,
            .vtable = .{
                .handle = &handle_impl,
            },
        };
    }

    pub fn handle_impl(self: *anyopaque, event: Event) void {
        const this: *MyWindow = @ptrCast(@alignCast(self));
        _ = this;
        switch (event) {
            .frame_buffer_size => |size| {
                glad.glViewport(0, 0, size.width, size.height);
            },
            else => {},
        }
    }
};

pub fn main(init: std.process.Init) !void {
    try glfw.init(init.gpa, .{});
    defer glfw.deinit();

    var window = try glfw.Window.create(1600, 900, "triangle", .{});
    defer window.destroy();
    var triangle: MyWindow = .{};
    window.setHandle(triangle.handle(), .{ .frame_buffer_size = true });
    window.makeContextCurrent();
    
    if (glad.gladLoadGLLoader(@ptrCast(&glfw.getProcAddress)) == 0) {
        return error.LoadGLFailed;
    }

    glad.glViewport(0, 0, 1600, 900);
    while (!window.shouldClose()) {
        glad.glClearColor(0.2, 0.3, 0.3, 1.0);
        glad.glClear(glad.GL_COLOR_BUFFER_BIT);

        window.swapBuffer();
        glfw.event.poll();
    }
}
