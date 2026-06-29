const glfw = @import("glfw3");
const std = @import("std");

pub const Window = @import("Window.zig");
pub const Monitor = @import("Monitor.zig");
pub const input = @import("input.zig");
pub const Image = @import("Image.zig");
pub const Cursor = @import("Cursor.zig");
pub const Handle = @import("Handle.zig");
const Allocator = std.mem.Allocator;

pub const Pos = struct { x: i32, y: i32 };
pub const f64Pos = struct { x: f64, y: f64 };
pub const Rectangle = struct { x: i32, y: i32, width: u32, height: u32 };
pub const Rectangle2 = struct { left: i32, top: i32, right: i32, bottom: i32 };
pub const Size = struct { width: u32, height: u32 };
pub const Scale = struct { x: f32, y: f32 };

pub const getProcAddress = glfw.getProcAddress;

pub const Platform2 = enum(c_int) {
    any = glfw.ANY_PLATFORM,
    win32 = glfw.PLATFORM_WIN32,
    cocoa = glfw.PLATFORM_COCOA,
    wayland = glfw.PLATFORM_WAYLAND,
    x11 = glfw.PLATFORM_X11,
    null = glfw.PLATFORM_NULL,
};

pub const AnglePlatformType = enum(c_int) {
    none = glfw.ANGLE_PLATFORM_TYPE_NONE,
    opengl = glfw.ANGLE_PLATFORM_TYPE_OPENGL,
    opengles = glfw.ANGLE_PLATFORM_TYPE_OPENGLES,
    d3d9 = glfw.ANGLE_PLATFORM_TYPE_D3D9,
    d3d11 = glfw.ANGLE_PLATFORM_TYPE_D3D11,
    vulkan = glfw.ANGLE_PLATFORM_TYPE_VULKAN,
    metal = glfw.ANGLE_PLATFORM_TYPE_METAL,
};

pub const WaylandLibdecor = enum(c_int) {
    prefer = glfw.WAYLAND_PREFER_LIBDECOR,
    disable = glfw.WAYLAND_DISABLE_LIBDECOR,
};

pub const Hint = struct {
    platform: ?Platform2 = null,
    joystick_hat_buttons: ?bool = null,
    angle_platform_type: ?AnglePlatformType = null,
    cocoa_chdir_resources: ?bool = null,
    cocoa_menubar: ?bool = null,
    wayland_libdecor: ?WaylandLibdecor = null,
    x11_xcb_vulkan_surface: ?bool = null,
};

inline fn b(v: bool) @TypeOf(glfw.TRUE) {
    return if (v) glfw.TRUE else glfw.FALSE;
}

fn inithint(hint: Hint) void {
    if (hint.platform) |platform| {
        glfw.initHint(glfw.PLATFORM, @intFromEnum(platform));
    }
    if (hint.joystick_hat_buttons) |joystick_hat_buttons| {
        glfw.initHint(glfw.JOYSTICK_HAT_BUTTONS, b(joystick_hat_buttons));
    }
    if (hint.angle_platform_type) |angle_platform_type| {
        glfw.initHint(glfw.ANGLE_PLATFORM_TYPE, @intFromEnum(angle_platform_type));
    }
    if (hint.cocoa_chdir_resources) |cocoa_chdir_resources| {
        glfw.initHint(glfw.COCOA_CHDIR_RESOURCES, b(cocoa_chdir_resources));
    }
    if (hint.cocoa_menubar) |cocoa_menubar| {
        glfw.initHint(glfw.COCOA_MENUBAR, b(cocoa_menubar));
    }
    if (hint.wayland_libdecor) |wayland_libdecor| {
        glfw.initHint(glfw.WAYLAND_LIBDECOR, @intFromEnum(wayland_libdecor));
    }
    if (hint.x11_xcb_vulkan_surface) |x11_xcb_vulkan_surface| {
        glfw.initHint(glfw.X11_XCB_VULKAN_SURFACE, b(x11_xcb_vulkan_surface));
    }
}

fn allocate(size: usize, user: ?*anyopaque) callconv(.c) ?*anyopaque {
    const allocator: *Allocator = @ptrCast(@alignCast(user.?));
    const ptr = allocator.alloc(
        u8,
        size + @sizeOf(usize),
    ) catch |err| switch (err) {
        error.OutOfMemory => return null,
    };
    const len: *usize = @ptrCast(@alignCast(ptr));
    len.* = size;
    return @ptrCast(@as([*]u8, @ptrCast(ptr)) + @sizeOf(usize));
}

fn reallocate(block: ?*anyopaque, size: usize, user: ?*anyopaque) callconv(.c) ?*anyopaque {
    const allocator: *Allocator = @ptrCast(@alignCast(user.?));
    const bptr: [*]u8 = @ptrCast(block orelse return null);
    const ptr = bptr - @sizeOf(usize);
    const len: *usize = @ptrCast(@alignCast(ptr));
    const nptr: []u8 = allocator.realloc(
        @as([]u8, @ptrCast(ptr[0..(len.* + @sizeOf(usize))])),
        size + @sizeOf(usize),
    ) catch |err| switch (err) {
        error.OutOfMemory => {
            return null;
        },
    };
    const nlen: *usize = @ptrCast(@alignCast(nptr));
    nlen.* = size;
    return @ptrCast(@as([*]u8, @ptrCast(nptr)) + @sizeOf(usize));
}

fn deallocate(block: ?*anyopaque, user: ?*anyopaque) callconv(.c) void {
    const allocator: *Allocator = @ptrCast(@alignCast(user.?));
    const bptr: [*]u8 = @ptrCast(block orelse return);
    const ptr = bptr - @sizeOf(usize);
    const len: *usize = @ptrCast(@alignCast(ptr));
    allocator.free(ptr[0..(len.* + @sizeOf(usize))]);
}

var custom_allocator: Allocator = undefined;

/// Initialize GLFW.
///
/// If `allocator` is not `null`, GLFW will use this allocator.
pub fn init(allocator: ?Allocator, hint: Hint) error{ PlatformUnavailable, InvalidValue }!void {
    inithint(hint);
    if (allocator) |alloc| {
        custom_allocator = alloc;
        const glfw_alloc = glfw.Allocator{
            .allocate = &allocate,
            .deallocate = &deallocate,
            .reallocate = &reallocate,
            .user = &custom_allocator,
        };
        glfw.initAllocator(&glfw_alloc);
    }
    const ret = glfw.init();
    if (ret == glfw.FALSE) {
        @branchHint(.cold);
        glfw.check() catch |err| switch (err) {
            error.PlatformUnavailable,
            error.InvalidValue,
            => return @errorCast(err),
            else => unreachable,
        };
    }
}

/// deinit GLFW.
pub inline fn deinit() void {
    glfw.terminate();
}

pub const event = struct {
    pub inline fn poll() void {
        glfw.pollEvents();
    }

    pub inline fn wait() void {
        glfw.waitEvents();
    }

    pub inline fn waitTimeout(timeout: f64) void {
        glfw.waitEventsTimeout(timeout);
    }

    pub inline fn postEmpty() void {
        glfw.postEmptyEvent();
    }
};

pub inline fn setCilpboard(string: []const u8) error{ClipboardBusy}!void {
    glfw.setClipboardString(null, string);
    if (glfw.getError(null) == glfw.PLATFORM_ERROR) {
        return error.ClipboardBusy;
    }
}

pub fn getClipborad() error{FormatUnavailable}!?[]const u8 {
    const str = glfw.getClipboardString(null);
    if (str == null) {
        @branchHint(.cold);
        if (glfw.getError(null) == glfw.PLATFORM_ERROR) {
            return error.ClipboardBusy;
        }
        glfw.check() catch |err| switch (err) {
            error.FormatUnavailable,
            => return @errorCast(err),
            else => unreachable,
        };
        return null;
    }
    return str[0..std.mem.len(str)];
}

pub inline fn getTime() f64 {
    return glfw.getTime();
}

pub fn setTime(time: f64) error{InvalidValue}!void {
    glfw.setTime(time);
    glfw.check() catch |err| switch (err) {
        error.InvalidValue => return @errorCast(err),
        else => unreachable,
    };
}

pub inline fn getTimerValue() u64 {
    return glfw.getTimerValue();
}

pub inline fn getTimerFrequency() u64 {
    return glfw.getTimerFrequency();
}

pub const Platform = enum(c_int) {
    win32 = glfw.PLATFORM_WIN32,
    cocoa = glfw.PLATFORM_COCOA,
    wayland = glfw.PLATFORM_WAYLAND,
    x11 = glfw.PLATFORM_X11,
    null = glfw.PLATFORM_NULL,
};

pub fn getPlatform() Platform {
    const p = glfw.getPlatform();
    if (p == 0) {
        glfw.check() catch unreachable;
        unreachable;
    }
    return @enumFromInt(p);
}

pub fn getPlatformSupport(platform: Platform) bool {
    return glfw.platformSupported(@intFromEnum(platform)) == glfw.TRUE;
}

pub fn swapInterval(interval: u32) void {
    glfw.swapInterval(@intCast(interval));
}

pub fn extensionSupported(extension: []const u8) error{ NoCurrentContext, InvalidValue }!bool {
    const ret = glfw.extensionSupported(extension);
    glfw.check() catch |err| switch (err) {
        error.NoCurrentContext,
        error.InvalidValue,
        => return @errorCast(err),
        else => unreachable,
    };
    return ret == glfw.TRUE;
}

pub fn hasVulkanSupport() bool {
    return glfw.vulkanSupported() == glfw.TRUE;
}

pub const getVersion = glfw.getVersion;
pub const getVersionString = glfw.getVersionString;
pub const setErrorCallback = glfw.setErrorCallback;

pub fn getRequiredInstanceExtensions() [][*c]const u8 {
    var count: u32 = undefined;
    const ret = glfw.getRequiredInstanceExtensions(&count);
    return ret[0..count];
}