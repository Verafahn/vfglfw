const std = @import("std");
const glfw = @import("vfglfw");
const gl = glfw.gl;
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
                gl.viewport(0, 0, size.width, size.height);
            },
            else => {},
        }
    }
};

const vertex_shader = @embedFile("vertex");
const fragment_shader = @embedFile("fragment");
const vertices = [_]f32{
    -0.5, -0.5, 0.0, 1.0, 0.0, 0.0,
    0.5,  -0.5, 0.0, 0.0, 1.0, 0.0,
    0.0,  0.5,  0.0, 0.0, 0.0, 1.0,
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
    window.setHandle(triangle.handle(), .{ .frame_buffer_size = true });
    window.makeContextCurrent();
    if (gl.loadGLLoader(@ptrCast(&glfw.getProcAddress)) == 0) {
        return error.LoadGLFailed;
    }
    gl.viewport(0, 0, 1600, 900);

    const vshader = gl.createShader(gl.VERTEX_SHADER);
    defer gl.deleteShader(vshader);
    gl.shaderBinary(
        1,
        &vshader,
        gl.SHADER_BINARY_FORMAT_SPIR_V,
        vertex_shader,
        vertex_shader.len,
    );
    gl.specializeShader(
        vshader,
        "main",
        0,
        null,
        null,
    );
    var success: c_int = undefined;
    var infolog: [512]u8 = undefined;
    gl.getShaderiv(vshader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(vshader, 512, null, &infolog);
        std.debug.print("{any}\n", .{infolog});
        return error.Vertex;
    }

    const fshader = gl.createShader(gl.FRAGMENT_SHADER);
    defer gl.deleteShader(fshader);
    gl.shaderBinary(
        1,
        &fshader,
        gl.SHADER_BINARY_FORMAT_SPIR_V,
        fragment_shader,
        fragment_shader.len,
    );
    gl.specializeShader(
        fshader,
        "main",
        0,
        null,
        null,
    );
    gl.getShaderiv(fshader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(vshader, 512, null, &infolog);
        std.debug.print("{any}\n", .{infolog});
        return error.Fragment;
    }

    const program = gl.createProgram();
    gl.attachShader(program, vshader);
    gl.attachShader(program, fshader);
    gl.linkProgram(program);

    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;
    gl.genVertexArrays(1, &vao);
    gl.genBuffers(1, &vbo);
    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        @sizeOf(@TypeOf(vertices)),
        &vertices,
        gl.STATIC_DRAW,
    );
    gl.vertexAttribPointer(
        0,
        3,
        gl.FLOAT,
        gl.FALSE,
        6 * @sizeOf(f32),
        null,
    );
    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(
        1,
        3,
        gl.FLOAT,
        gl.FALSE,
        6 * @sizeOf(f32),
        @ptrFromInt(3 * @sizeOf(f32)),
    );
    gl.enableVertexAttribArray(1);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bindVertexArray(vao);

    while (!window.shouldClose()) {
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(program);
        gl.bindVertexArray(vao);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        window.swapBuffer();
        glfw.event.poll();
    }
}
