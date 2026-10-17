const frag_color = @extern(
    *addrspace(.output) @Vector(4, f32),
    .{
        .name = "frag_color",
    },
);
const f_color = @extern(
    *addrspace(.input) @Vector(3, f32),
    .{
        .name = "f_color",
    },
);

export fn main() callconv(.{ .spirv_fragment = .{} }) void {
    frag_color.* = .{ f_color.*[0], f_color.*[1], f_color.*[2], 0.0 };
}
