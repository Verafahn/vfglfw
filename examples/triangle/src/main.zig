const std = @import("std");
const glfw = @import("vfglfw");
const glad = @import("glad");
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
            .frame_buffer_size => |size| {
                glad.glViewport(0, 0, size.width, size.height);
            },
            else => {},
        }
    }
};

const vertex_shader = @embedFile("vertex");
const fragment_shader = @embedFile("fragment");
const vertices = [_]f32{
    -0.5, -0.5, 0.0,
    0.5,  -0.5, 0.0,
    0.0,  0.5,  0.0,
};

pub fn main(init: std.process.Init) !void {
    try glfw.init(init.gpa, .{});
    defer glfw.deinit();

    var window = try glfw.Window.create(1600, 900, "triangle", .{});
    defer window.destroy();
    var triangle: Triangle = .{};
    window.setHandle(triangle.handle(), .{ .frame_buffer_size = true });
    window.makeContextCurrent();
    if (glad.gladLoadGLLoader(@ptrCast(&glfw.getProcAddress)) == 0) {
        return error.LoadGLFailed;
    }
    glad.glViewport(0, 0, 1600, 900);

    const vshader = glad.glCreateShader(glad.GL_VERTEX_SHADER);
    defer glad.glDeleteShader(vshader);
    glad.glShaderBinary(
        1,
        &vshader,
        glad.GL_SHADER_BINARY_FORMAT_SPIR_V,
        vertex_shader,
        vertex_shader.len,
    );
    glad.glSpecializeShader(
        vshader,
        "main",
        0,
        null,
        null,
    );
    var success: c_int = undefined;
    var infolog: [512]u8 = undefined;
    glad.glGetShaderiv(vshader, glad.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        glad.glGetShaderInfoLog(vshader, 512, null, &infolog);
        std.debug.print("{any}\n", .{infolog});
        return error.Vertex;
    }

    const fshader = glad.glCreateShader(glad.GL_FRAGMENT_SHADER);
    defer glad.glDeleteShader(fshader);
    glad.glShaderBinary(
        1,
        &fshader,
        glad.GL_SHADER_BINARY_FORMAT_SPIR_V,
        fragment_shader,
        fragment_shader.len,
    );
    glad.glSpecializeShader(
        fshader,
        "main",
        0,
        null,
        null,
    );
    glad.glGetShaderiv(fshader, glad.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        glad.glGetShaderInfoLog(vshader, 512, null, &infolog);
        std.debug.print("{any}\n", .{infolog});
        return error.Fragment;
    }

    const program = glad.glCreateProgram();
    glad.glAttachShader(program, vshader);
    glad.glAttachShader(program, fshader);
    glad.glLinkProgram(program);

    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;
    glad.glGenVertexArrays(1, &vao);
    glad.glGenBuffers(1, &vbo);
    glad.glBindVertexArray(vao);
    glad.glBindBuffer(glad.GL_ARRAY_BUFFER, vbo);
    glad.glBufferData(
        glad.GL_ARRAY_BUFFER,
        @sizeOf(@TypeOf(vertices)),
        &vertices,
        glad.GL_STATIC_DRAW,
    );
    glad.glVertexAttribPointer(
        0,
        2,
        glad.GL_FLOAT,
        glad.GL_FALSE,
        3 * @sizeOf(f32),
        null,
    );
    glad.glEnableVertexAttribArray(0);
    glad.glBindBuffer(glad.GL_ARRAY_BUFFER, vbo);
    glad.glBindVertexArray(vao);

    while (!window.shouldClose()) {
        glad.glClearColor(0.2, 0.3, 0.3, 1.0);
        glad.glClear(glad.GL_COLOR_BUFFER_BIT);

        glad.glUseProgram(program);
        glad.glBindVertexArray(vao);
        glad.glDrawArrays(glad.GL_TRIANGLES, 0, 3);

        window.swapBuffer();
        glfw.event.poll();
    }
}
