const glfw = @import("glfw3");
const Monitor = @This();
const std = @import("std");
const Allocator = std.mem.Allocator;
const types = @import("root.zig");

impl: *glfw.Monitor,

pub fn getPrimaryMonitor() ?Monitor {
    const monitor = glfw.getPrimaryMonitor();
    if (monitor == null) {
        glfw.check() catch unreachable;
        return null;
    }
    return .{ .impl = monitor.? };
}

/// **The caller owns the returned memory.**
pub fn getMonitors(alloctator: Allocator) []Monitor {
    var count: c_int = undefined;
    const monitors = glfw.getMonitors(&count);
    if (monitors == null) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
        return &.{};
    }
    var array = try std.ArrayList(Monitor).initCapacity(alloctator, count);
    defer array.deinit(alloctator);
    for (0..count) |i| {
        array.append(alloctator, .{ .impl = monitors[i].? });
    }
    return array.toOwnedSlice(alloctator);
}

const Pos = types.Pos;
const Rectangle = types.Rectangle;
const Size = types.Size;
const Scale = types.Scale;

pub fn getPos(self: *const Monitor) Pos {
    var x: c_int = undefined;
    var y: c_int = undefined;
    glfw.getMonitorPos(self.impl, &x, &y);
    if (x == 0 and y == 0) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
    }
    return .{ .x = @intCast(x), .y = @intCast(y) };
}

pub fn getWorkarea(self: *const Monitor) Rectangle {
    var x: c_int = undefined;
    var y: c_int = undefined;
    var width: c_int = undefined;
    var height: c_int = undefined;
    glfw.getMonitorWorkarea(self.impl, &x, &y, &width, &height);
    if (x == 0 and y == 0 and width == 0 and height == 0) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
    }
    return .{
        .x = @intCast(x),
        .y = @intCast(y),
        .width = @intCast(width),
        .height = @intCast(height),
    };
}

pub fn getPhysicalSize(self: *const Monitor) Size {
    var width: c_int = undefined;
    var height: c_int = undefined;
    glfw.getMonitorPhysicalSize(self.impl, &width, &height);
    if (width == 0 and height == 0) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
    }
    return .{
        .width = @intCast(width),
        .height = @intCast(height),
    };
}

pub fn getContentScale(self: *const Monitor) !Scale {
    var x: f32 = undefined;
    var y: f32 = undefined;
    glfw.getMonitorContentScale(self.impl, &x, &y);
    glfw.check() catch unreachable;
    return .{ .x = x, .y = y };
}

pub fn getName(self: *const Monitor) []const u8 {
    const name = glfw.getMonitorName(self.impl);
    if (name == null) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
        unreachable;
    }
    return name[0..std.mem.len(name)];
}
