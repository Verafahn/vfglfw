const glfw = @import("glfw3");
const std = @import("std");

pub const gl =
    if (@import("use_gl").enable_gl)
        @import("gl/root.zig")
    else
        @compileError("Use '-Duse_gl' to enable it.");
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

/// Raw GLFW function for loaders such as GLAD. `procname` must be
/// NUL-terminated.
pub const getProcAddress = glfw.getProcAddress;

/// Type-safe variant of `getProcAddress` for NUL-terminated names.
pub fn getProcAddressZ(procname: [:0]const u8) glfw.GLProc {
    return glfw.getProcAddress(procname.ptr);
}

pub const Platform = enum(c_int) {
    win32 = glfw.PLATFORM_WIN32,
    cocoa = glfw.PLATFORM_COCOA,
    wayland = glfw.PLATFORM_WAYLAND,
    x11 = glfw.PLATFORM_X11,
    null = glfw.PLATFORM_NULL,
};

pub const PlatformHint = enum(c_int) {
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
    platform: ?PlatformHint = null,
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
        glfw.initHint(glfw.PLATFORM, @backingInt(platform));
    }
    if (hint.joystick_hat_buttons) |joystick_hat_buttons| {
        glfw.initHint(glfw.JOYSTICK_HAT_BUTTONS, b(joystick_hat_buttons));
    }
    if (hint.angle_platform_type) |angle_platform_type| {
        glfw.initHint(glfw.ANGLE_PLATFORM_TYPE, @backingInt(angle_platform_type));
    }
    if (hint.cocoa_chdir_resources) |cocoa_chdir_resources| {
        glfw.initHint(glfw.COCOA_CHDIR_RESOURCES, b(cocoa_chdir_resources));
    }
    if (hint.cocoa_menubar) |cocoa_menubar| {
        glfw.initHint(glfw.COCOA_MENUBAR, b(cocoa_menubar));
    }
    if (hint.wayland_libdecor) |wayland_libdecor| {
        glfw.initHint(glfw.WAYLAND_LIBDECOR, @backingInt(wayland_libdecor));
    }
    if (hint.x11_xcb_vulkan_surface) |x11_xcb_vulkan_surface| {
        glfw.initHint(glfw.X11_XCB_VULKAN_SURFACE, b(x11_xcb_vulkan_surface));
    }
}

const max_align = @alignOf(std.c.max_align_t);
const alloc_header = std.mem.alignForward(usize, @sizeOf(usize), max_align);

fn allocate(size: usize, user: ?*anyopaque) callconv(.c) ?*anyopaque {
    const allocator: *Allocator = @ptrCast(@alignCast(user.?));
    const total = std.math.add(usize, size, alloc_header) catch return null;
    const memory = allocator.alignedAlloc(
        u8,
        .fromByteUnits(max_align),
        total,
    ) catch return null;

    const header: *usize = @ptrCast(@alignCast(memory.ptr));
    header.* = size;
    return memory.ptr + alloc_header;
}

fn reallocate(block: ?*anyopaque, size: usize, user: ?*anyopaque) callconv(.c) ?*anyopaque {
    const allocator: *Allocator = @ptrCast(@alignCast(user.?));
    const block_ptr: [*]u8 = @ptrCast(block orelse return null);
    const base = block_ptr - alloc_header;
    const header: *usize = @ptrCast(@alignCast(base));

    const old_size = std.math.add(usize, header.*, alloc_header) catch return null;
    const old_memory: []align(max_align) u8 = @alignCast(base[0..old_size]);

    const total = std.math.add(usize, size, alloc_header) catch return null;
    const memory = allocator.realloc(old_memory, total) catch return null;

    const new_header: *usize = @ptrCast(@alignCast(memory.ptr));
    new_header.* = size;
    return memory.ptr + alloc_header;
}

fn deallocate(block: ?*anyopaque, user: ?*anyopaque) callconv(.c) void {
    const allocator: *Allocator = @ptrCast(@alignCast(user.?));
    const block_ptr: [*]u8 = @ptrCast(block orelse return);
    const base = block_ptr - alloc_header;
    const header: *usize = @ptrCast(@alignCast(base));

    const total = header.* + alloc_header;
    const memory: []align(max_align) u8 = @alignCast(base[0..total]);
    allocator.free(memory);
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
    } else {
        glfw.initAllocator(null);
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

/// Sets the system clipboard. `window` may be null when the platform does not
/// require a window to own the clipboard contents.
pub fn setClipboard(window: ?Window, string: [:0]const u8) error{ClipboardBusy}!void {
    const impl = if (window) |w| w.impl else null;
    glfw.setClipboardString(impl, string.ptr);
    if (glfw.getError(null) == glfw.PLATFORM_ERROR) {
        return error.ClipboardBusy;
    }
}

/// Returns the clipboard contents. The returned slice is owned by GLFW and is
/// valid until the next clipboard call or `deinit`.
pub fn getClipboard(window: ?Window) error{ FormatUnavailable, ClipboardBusy }!?[]const u8 {
    const impl = if (window) |w| w.impl else null;
    const str = glfw.getClipboardString(impl);
    if (str == null) {
        @branchHint(.cold);
        return switch (glfw.getError(null)) {
            glfw.NO_ERROR => null,
            glfw.FORMAT_UNAVAILABLE => error.FormatUnavailable,
            glfw.PLATFORM_ERROR => error.ClipboardBusy,
            else => error.FormatUnavailable,
        };
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

pub fn getPlatform() Platform {
    const p = glfw.getPlatform();
    if (p == 0) {
        glfw.check() catch unreachable;
        unreachable;
    }
    return @fromBackingInt(@intCast(p));
}

pub fn getPlatformSupport(platform: PlatformHint) bool {
    return glfw.platformSupported(@backingInt(platform)) == glfw.TRUE;
}

pub fn swapInterval(interval: i32) void {
    glfw.swapInterval(interval);
}

pub fn extensionSupported(extension: [:0]const u8) error{ NoCurrentContext, InvalidValue }!bool {
    const ret = glfw.extensionSupported(extension.ptr);
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

pub const ErrorInfo = struct {
    code: c_int,
    /// Valid until the next GLFW error.
    description: ?[:0]const u8,
};

/// Returns and clears the last GLFW error.
pub fn getError() ErrorInfo {
    var description: [*c]const u8 = null;
    const code = glfw.getError(&description);
    if (description == null) {
        return .{ .code = code, .description = null };
    }
    const len = std.mem.len(description);
    return .{ .code = code, .description = description[0..len :0] };
}

pub const getVersion = glfw.getVersion;
pub const getVersionString = glfw.getVersionString;
pub const setErrorCallback = glfw.setErrorCallback;

pub fn getRequiredInstanceExtensions() ?[]const [*c]const u8 {
    var count: u32 = undefined;
    const ret = glfw.getRequiredInstanceExtensions(&count);
    if (ret == null) return null;
    return ret[0..@intCast(count)];
}
