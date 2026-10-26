const std = @import("std");
const spirv = std.spirv;

const pos = @extern(
    *addrspace(.input) @Vector(3, f32),
    .{
        .name = "pos",
        .decoration = .{ .location = 0 },
    },
);
const v_color = @extern(
    *addrspace(.input) @Vector(3, f32),
    .{
        .name = "v_color",
        .decoration = .{ .location = 1 },
    },
);
extern var f_color: @Vector(3, f32) addrspace(.output);

export fn main() callconv(.spirv_vertex) void {
    spirv.position_out.* = .{ pos.*[0], pos.*[1], pos.*[2], 1.0 };
    f_color = v_color.*;
}
