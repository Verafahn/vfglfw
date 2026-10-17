const std = @import("std");
const spirv = std.spirv;

const pos = @extern(
    *addrspace(.input) @Vector(3, f32),
    .{
        .name = "pos",
        .decoration = .{ .location = 0 },
    },
);

export fn main() callconv(.spirv_vertex) void {
    spirv.position_out.* = .{ pos.*[0], pos.*[1], pos.*[2], 1.0 };
}
