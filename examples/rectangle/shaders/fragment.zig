extern var frag_color: @Vector(4, f32) addrspace(.output);
extern const f_color: @Vector(3, f32) addrspace(.input);

export fn main() callconv(.{ .spirv_fragment = .{} }) void {
    frag_color = .{ f_color[0], f_color[1], f_color[2], 0.0 };
}
