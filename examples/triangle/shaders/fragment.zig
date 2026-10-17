const frag_color = @extern(
    *addrspace(.output) @Vector(4, f32),
    .{
        .name = "frag_color",
        .decoration = .{ .location = 0 },
    },
);

export fn main() callconv(.{ .spirv_fragment = .{} }) void {
    frag_color.* = .{ 1.0, 0.5, 0.2, 1.0 };
}
