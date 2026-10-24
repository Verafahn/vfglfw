const std = @import("std");
const gl = @import("glad");
const Shader = @This();
const Allocator = std.mem.Allocator;

id: c_uint,

pub const ShaderParam = struct {
    spir_v: []const u8,
    entry: []const u8,
};
pub const ShaderBinary = struct {
    vertex: ShaderParam,
    fragment: ShaderParam,
};
pub const Diagnosis = struct {
    gpa: Allocator,
    info: []const u8,

    pub fn deinit(self: *Diagnosis) void {
        for (self.info.items) |p| {
            self.gpa.free(p);
        }
        self.info.deinit(self.gpa);
    }
};

pub const Error = error{
    VertexShaderCompileFailed,
    FragmentShaderCompileFailed,
} || Allocator.Error;

pub fn createBinary(param: ShaderBinary, diag: ?*Diagnosis) Error!Shader {
    const vs = gl.createShader(gl.VERTEX_SHADER);
    const fs = gl.createShader(gl.FRAGMENT_SHADER);
    defer {
        gl.deleteShader(vs);
        gl.deleteShader(fs);
    }
    // vertex
    gl.shaderBinary(
        1,
        &vs,
        gl.SHADER_BINARY_FORMAT_SPIR_V,
        @ptrCast(param.vertex.spir_v),
        @intCast(param.vertex.spir_v.len),
    );
    gl.specializeShader(
        vs,
        @ptrCast(param.vertex.entry),
        0,
        null,
        null,
    );
    var res: c_int = undefined;
    gl.getShaderiv(vs, gl.COMPILE_STATUS, &res);
    if (res == 0) {
        if (diag) |d| {
            gl.getShaderiv(vs, gl.INFO_LOG_LENGTH, &res);
            const info = try d.gpa.alloc(u8, @intCast(res));
            gl.getShaderInfoLog(vs, @intCast(info.len), null, @ptrCast(info));
            d.info = info;
        }
        return Error.VertexShaderCompileFailed;
    }
    // fragment
    gl.shaderBinary(
        1,
        &fs,
        gl.SHADER_BINARY_FORMAT_SPIR_V,
        @ptrCast(param.fragment.spir_v),
        @intCast(param.fragment.spir_v.len),
    );
    gl.specializeShader(
        fs,
        @ptrCast(param.fragment.entry),
        0,
        null,
        null,
    );
    gl.getShaderiv(fs, gl.COMPILE_STATUS, &res);
    if (res == 0) {
        if (diag) |d| {
            gl.getShaderiv(fs, gl.INFO_LOG_LENGTH, &res);
            const info = try d.gpa.alloc(u8, @intCast(res));
            gl.getShaderInfoLog(fs, @intCast(info.len), null, @ptrCast(info));
            d.info = info;
        }
        return Error.FragmentShaderCompileFailed;
    }

    const program = gl.createProgram();
    gl.attachShader(program, vs);
    gl.attachShader(program, fs);
    gl.linkProgram(program);

    return .{
        .id = program,
    };
}

pub fn destroy(self: Shader) void {
    gl.deleteProgram(self.id);
}

pub fn use(self: Shader) void {
    gl.useProgram(self.id);
}