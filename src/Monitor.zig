const glfw = @import("glfw3");
const Monitor = @This();
const std = @import("std");
const Allocator = std.mem.Allocator;
const types = @import("root.zig");

impl: *glfw.Monitor,
handle: ?Handle = null,

pub const Handle = struct {
    vptr: *anyopaque,
    vtable: VTable,

    pub const VTable = struct {
        callback: *const fn (*anyopaque, event: Event) void,
    };
};

pub const Event = enum(@TypeOf(glfw.CONNECTED)) {
    connected = glfw.CONNECTED,
    disconnected = glfw.DISCONNECTED,
};

fn when_callback(self: ?*glfw.Monitor, event: c_int) callconv(.c) void {
    const this: *Monitor = @ptrCast(@alignCast(glfw.getMonitorUserPointer(self)));
    if (this.handle) |handle| {
        handle.vtable.callback(this.handle.?.vptr, @enumFromInt(event));
    }
}

pub fn setHandle(self: *Monitor, handle: Handle) void {
    _ = glfw.setMonitorCallback(when_callback);
    glfw.setMonitorUserPointer(self.impl, self);
    self.handle = handle;
}

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

pub fn getPos(self: Monitor) Pos {
    var x: c_int = undefined;
    var y: c_int = undefined;
    glfw.getMonitorPos(self.impl, &x, &y);
    if (x == 0 and y == 0) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
    }
    return .{ .x = @intCast(x), .y = @intCast(y) };
}

pub fn getWorkarea(self: Monitor) Rectangle {
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

pub fn getPhysicalSize(self: Monitor) Size {
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

pub fn getContentScale(self: Monitor) !Scale {
    var x: f32 = undefined;
    var y: f32 = undefined;
    glfw.getMonitorContentScale(self.impl, &x, &y);
    glfw.check() catch unreachable;
    return .{ .x = x, .y = y };
}

pub fn getName(self: Monitor) []const u8 {
    const name = glfw.getMonitorName(self.impl);
    if (name == null) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
        unreachable;
    }
    return name[0..std.mem.len(name)];
}

pub fn getVideoModes(self: Monitor) []glfw.VidMode {
    var count: c_int = undefined;
    const ret = glfw.getVideoModes(self.impl, &count);
    if (ret == null) {
        glfw.check() catch unreachable;
    }
    return ret[0..@as(usize, count)];
}

pub fn getVideoMode(self: Monitor) *const glfw.VidMode {
    return @ptrCast(glfw.getVideoMode(self.impl));
}

pub fn setGamma(self: Monitor, gamma: f32) void {
    glfw.setGamma(self.impl, gamma);
}

pub fn getGammaRamp(self: Monitor) *glfw.GammaRamp {
    const ret = glfw.getGammaRamp(self.impl);
    if (ret == null) {
        try glfw.check();
    }
    return @ptrCast(ret);
}

pub fn setGammaRamp(self: Monitor, ramp: *glfw.GammaRamp) void {
    glfw.setGammaRamp(self.impl, ramp);
}
