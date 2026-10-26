const std = @import("std");
const Vertex = @This();
const gl = @import("glad");

vao: c_uint,
vbo: c_uint,
ebo: ?c_uint = null,

pub const Mode = enum(c_uint) {
    stream_draw = gl.STREAM_DRAW,
    stream_read = gl.STREAM_READ,
    stream_copy = gl.STREAM_COPY,
    static_draw = gl.STATIC_DRAW,
    static_read = gl.STATIC_READ,
    static_copy = gl.STATIC_COPY,
    dynamic_draw = gl.DYNAMIC_DRAW,
    dynamic_read = gl.DYNAMIC_READ,
    dynamic_copy = gl.DYNAMIC_COPY,
};

pub fn create(comptime T: type, vertices: []const T, mode: Mode) Vertex {
    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;
    gl.genVertexArrays(1, &vao);
    gl.genBuffers(1, &vbo);
    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    defer {
        gl.bindVertexArray(0);
        gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    }
    gl.bufferData(
        gl.ARRAY_BUFFER,
        @intCast(@sizeOf(T) * vertices.len),
        @ptrCast(vertices),
        @backingInt(mode),
    );
    genVertexAttribPointer(T);

    return .{ .vao = vao, .vbo = vbo };
}

pub fn createWithEBO(comptime T: type, vertices: []const T, comptime U: type, indices: []const U, mode: Mode) Vertex {
    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;
    var ebo: c_uint = undefined;
    gl.genVertexArrays(1, &vao);
    gl.genBuffers(1, &vbo);
    gl.genBuffers(1, &ebo);
    gl.bindVertexArray(vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    defer {
        gl.bindVertexArray(0);
        gl.bindBuffer(gl.ARRAY_BUFFER, 0);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    }
    gl.bufferData(
        gl.ARRAY_BUFFER,
        @intCast(@sizeOf(T) * vertices.len),
        @ptrCast(vertices),
        @backingInt(mode),
    );
    gl.bufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        @intCast(@sizeOf(U) * indices.len),
        @ptrCast(indices),
        @backingInt(mode),
    );
    genVertexAttribPointer(T);

    return .{ .vao = vao, .vbo = vbo, .ebo = ebo };
}

fn genVertexAttribPointer(comptime T: type) void {
    const info = @typeInfo(T);
    if (info != .@"struct") @compileError("Vertex must be struct.");
    inline for (info.@"struct".field_names, info.@"struct".field_types, 0..) |name, ty, i| {
        const ty_info = @typeInfo(ty);
        if (ty_info != .vector) @compileError("Vertex fields must be @Vecter(...).");
        const len = ty_info.vector.len;
        const child = ty_info.vector.child;

        const func, const type_ = blk: switch (@typeInfo(child)) {
            .int => |int| {
                const t = switch (int.signedness) {
                    .unsigned => switch (int.bits) {
                        8 => gl.UNSIGNED_BYTE,
                        16 => gl.UNSIGNED_SHORT,
                        32 => gl.UNSIGNED_INT,
                        else => unreachable,
                    },
                    .signed => switch (int.bits) {
                        8 => gl.BYTE,
                        16 => gl.SHORT,
                        32 => gl.INT,
                        else => unreachable,
                    },
                };
                break :blk .{ gl.vertexAttribIPointer, t };
            },
            .float => |f| {
                const t = switch (f.bits) {
                    16 => gl.HALF_FLOAT,
                    32 => gl.FLOAT,
                    64 => break :blk .{ gl.vertexAttribLPointer, gl.DOUBLE },
                    else => unreachable,
                };
                break :blk .{ gl.vertexAttribPointer, t };
            },
            else => unreachable,
        };

        func(
            i,
            len,
            type_,
            gl.FALSE,
            @sizeOf(T),
            @ptrFromInt(@offsetOf(T, name)),
        );
        gl.enableVertexAttribArray(i);
    }
}

pub fn destroy(self: Vertex) void {
    gl.deleteVertexArrays(1, &self.vao);
    gl.deleteBuffers(1, &self.vbo);
    if (self.ebo) |ebo| gl.deleteBuffers(1, &ebo);
}

pub fn bind(self: Vertex) void {
    gl.bindVertexArray(self.vao);
}
