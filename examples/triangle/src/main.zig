const std = @import("std");
const glfw = @import("vfglfw");
const gl = glfw.gl;
const api = gl.gl;
const Event = glfw.Handle.Event;

pub const Triangle = struct {
    pub fn handle(self: *Triangle) glfw.Handle {
        return .{
            .vptr = self,
            .vtable = .{
                .handle = &handle_impl,
            },
        };
    }

    pub fn handle_impl(self: *anyopaque, event: Event) void {
        const this: *Triangle = @ptrCast(@alignCast(self));
        _ = this;
        switch (event) {
            .framebuffer_size => |size| {
                api.viewport(0, 0, size.width, size.height);
            },
            else => {},
        }
    }
};

pub const ColorPoint = struct {
    pos: @Vector(3, f32),
    color: @Vector(3, f32),
};

const vertices = [_]ColorPoint{
    .{ .pos = .{ -0.5, -0.5, 0.0 }, .color = .{ 1.0, 0.0, 0.0 } },
    .{ .pos = .{ 0.5, -0.5, 0.0 }, .color = .{ 0.0, 1.0, 0.0 } },
    .{ .pos = .{ 0.0, 0.5, 0.0 }, .color = .{ 0.0, 0.0, 1.0 } },
};

pub fn main(init: std.process.Init) !void {
    try glfw.init(init.gpa, .{});
    defer glfw.deinit();

    var window = try glfw.Window.create(1600, 900, "triangle", .{
        .context_version_major = 4,
        .context_version_minor = 6,
        .opengl_profile = .core,
    });
    defer window.destroy();
    var triangle: Triangle = .{};
    try window.setHandle(triangle.handle(), .{ .framebuffer_size = true });
    window.makeContextCurrent();
    if (api.loadGLLoader(@ptrCast(&glfw.getProcAddress)) == 0) {
        return error.LoadGLFailed;
    }
    api.viewport(0, 0, 1600, 900);

    const shader = try gl.Shader.createBinary(.{
        .vertex = .{
            .spir_v = @embedFile("vertex"),
            .entry = "main",
        },
        .fragment = .{
            .spir_v = @embedFile("fragment"),
            .entry = "main",
        },
    }, null);

    const vertex = gl.Vertex.create(ColorPoint, &vertices, .static_draw);
    defer vertex.destroy();

    while (!window.shouldClose()) {
        api.clearColor(0.2, 0.3, 0.3, 1.0);
        api.clear(api.COLOR_BUFFER_BIT);

        shader.use();
        vertex.bind();
        api.drawArrays(api.TRIANGLES, 0, 3);

        window.swapBuffers();
        glfw.event.poll();
    }
}
