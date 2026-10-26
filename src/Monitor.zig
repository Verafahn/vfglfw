const glfw = @import("glfw3");
const Monitor = @This();
const std = @import("std");
const Allocator = std.mem.Allocator;
const types = @import("root.zig");

impl: *glfw.Monitor,

pub const Handle = struct {
    vptr: *anyopaque,
    vtable: VTable,

    pub const VTable = struct {
        callback: *const fn (*anyopaque, event: Event) void,
    };
};

/// A monitor hotplug event. The `Monitor` payload is only valid for the
/// duration of the callback.
pub const Event = union(enum) {
    connected: Monitor,
    disconnected: Monitor,
};

var global_handle: ?Handle = null;

fn whenCallback(monitor: ?*glfw.Monitor, event: c_int) callconv(.c) void {
    const handle = global_handle orelse return;
    const impl = monitor orelse return;
    const mon: Monitor = .{ .impl = impl };

    if (event == glfw.CONNECTED) {
        handle.vtable.callback(handle.vptr, .{ .connected = mon });
    } else if (event == glfw.DISCONNECTED) {
        handle.vtable.callback(handle.vptr, .{ .disconnected = mon });
    }
}

/// Sets the global monitor callback. GLFW monitor events are not scoped to a
/// single monitor, so the handle receives events for every monitor.
pub fn setCallback(handle: ?Handle) void {
    global_handle = handle;
    _ = glfw.setMonitorCallback(if (handle != null) &whenCallback else null);
}

pub fn getPrimaryMonitor() ?Monitor {
    const monitor = glfw.getPrimaryMonitor() orelse return null;
    return .{ .impl = monitor };
}

/// **The caller owns the returned memory.**
pub fn getMonitors(allocator: Allocator) ![]Monitor {
    var count: c_int = undefined;
    const monitors = glfw.getMonitors(&count);
    if (monitors == null) {
        try glfw.check();
        return allocator.alloc(Monitor, 0);
    }

    const n: usize = @intCast(count);
    const result = try allocator.alloc(Monitor, n);
    for (0..n) |i| {
        result[i] = .{ .impl = monitors[i].? };
    }
    return result;
}

const Pos = types.Pos;
const Rectangle = types.Rectangle;
const Size = types.Size;
const Scale = types.Scale;

pub fn getPos(self: Monitor) Pos {
    var x: c_int = undefined;
    var y: c_int = undefined;
    glfw.getMonitorPos(self.impl, &x, &y);
    glfw.check() catch unreachable;
    return .{ .x = @intCast(x), .y = @intCast(y) };
}

pub fn getWorkarea(self: Monitor) Rectangle {
    var x: c_int = undefined;
    var y: c_int = undefined;
    var width: c_int = undefined;
    var height: c_int = undefined;
    glfw.getMonitorWorkarea(self.impl, &x, &y, &width, &height);
    glfw.check() catch unreachable;
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
    glfw.check() catch unreachable;
    return .{
        .width = @intCast(width),
        .height = @intCast(height),
    };
}

pub fn getContentScale(self: Monitor) Scale {
    var x: f32 = undefined;
    var y: f32 = undefined;
    glfw.getMonitorContentScale(self.impl, &x, &y);
    glfw.check() catch unreachable;
    return .{ .x = x, .y = y };
}

pub fn getName(self: Monitor) []const u8 {
    const name = glfw.getMonitorName(self.impl) orelse {
        glfw.check() catch unreachable;
        unreachable;
    };
    return name[0..std.mem.len(name)];
}

pub fn getVideoModes(self: Monitor) []const glfw.VidMode {
    var count: c_int = undefined;
    const modes = glfw.getVideoModes(self.impl, &count) orelse return &.{};
    return modes[0..@intCast(count)];
}

pub fn getVideoMode(self: Monitor) ?*const glfw.VidMode {
    const mode = glfw.getVideoMode(self.impl) orelse return null;
    return @ptrCast(mode);
}

pub fn setGamma(self: Monitor, gamma: f32) error{InvalidValue}!void {
    glfw.setGamma(self.impl, gamma);
    glfw.check() catch |err| switch (err) {
        error.InvalidValue => return @errorCast(err),
        else => unreachable,
    };
}

pub fn getGammaRamp(self: Monitor) ?*const glfw.GammaRamp {
    const ramp = glfw.getGammaRamp(self.impl) orelse return null;
    return @ptrCast(ramp);
}

pub fn setGammaRamp(self: Monitor, ramp: *const glfw.GammaRamp) void {
    glfw.setGammaRamp(self.impl, ramp);
}

pub fn setUserPointer(self: Monitor, ptr: ?*anyopaque) void {
    glfw.setMonitorUserPointer(self.impl, ptr);
}

pub fn getUserPointer(self: Monitor, comptime T: type) ?*T {
    const ptr = glfw.getMonitorUserPointer(self.impl) orelse return null;
    return @ptrCast(@alignCast(ptr));
}
