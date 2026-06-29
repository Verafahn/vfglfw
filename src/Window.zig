const glfw = @import("glfw3");
const Monitor = @import("Monitor.zig");
const Window = @This();
const types = @import("root.zig");
const Image = @import("Image.zig");
const std = @import("std");
const Allocator = std.mem.Allocator;
const input = @import("input.zig");
const ModeType = input.ModeType;
const Mode = input.Mode;
const Key = input.Key;
const State = input.State;
const Button = input.MouseButton;
const Rectangle = types.Rectangle2;
const Action = input.Action;
const Modify = input.Modify;
const Cursor = @import("Cursor.zig");
const Handle = @import("Handle.zig");

impl: *glfw.Window,
handle_impl: ?Handle = null,

pub const ClientApi = enum(c_int) {
    opengl = glfw.OPENGL_API,
    opengles = glfw.OPENGL_ES_API,
    noapi = glfw.NO_API,
};

pub const CreationApi = enum(c_int) {
    native = glfw.NATIVE_CONTEXT_API,
    egl = glfw.EGL_CONTEXT_API,
    osmesa = glfw.OSMESA_CONTEXT_API,
};

pub const Robustness = enum(c_int) {
    no_robustness = glfw.NO_ROBUSTNESS,
    no_reset_notification = glfw.NO_RESET_NOTIFICATION,
    lose_context_on_reset = glfw.LOSE_CONTEXT_ON_RESET,
};

pub const ReleaseBehavior = enum(c_int) {
    any = glfw.ANY_RELEASE_BEHAVIOR,
    flush = glfw.RELEASE_BEHAVIOR_FLUSH,
    none = glfw.RELEASE_BEHAVIOR_NONE,
};

pub const Profile = enum(c_int) {
    any = glfw.OPENGL_ANY_PROFILE,
    compat = glfw.OPENGL_COMPAT_PROFILE,
    core = glfw.OPENGL_CORE_PROFILE,
};

pub const Hint = struct {
    monitor: ?Monitor = null,
    share: ?Window = null,

    resizable: ?bool = null,
    visible: ?bool = null,
    decorated: ?bool = null,
    focused: ?bool = null,
    auto_iconify: ?bool = null,
    floating: ?bool = null,
    maximized: ?bool = null,
    center_cursor: ?bool = null,
    transparent_framebuffer: ?bool = null,
    focus_on_show: ?bool = null,
    scale_to_monitor: ?bool = null,
    scale_framebuffer: ?bool = null,
    mouse_passthrough: ?bool = null,
    position_x: ?union(enum) { any, pos: u32 } = null,
    position_y: ?union(enum) { any, pos: u32 } = null,
    red_bits: ?union(enum) { dont_care, bits: u31 } = null,
    green_bits: ?union(enum) { dont_care, bits: u31 } = null,
    blue_bits: ?union(enum) { dont_care, bits: u31 } = null,
    alpha_bits: ?union(enum) { dont_care, bits: u31 } = null,
    depth_bits: ?union(enum) { dont_care, bits: u31 } = null,
    stencil_bits: ?union(enum) { dont_care, bits: u31 } = null,
    accum_red_bits: ?union(enum) { dont_care, bits: u31 } = null,
    accum_green_bits: ?union(enum) { dont_care, bits: u31 } = null,
    accum_blue_bits: ?union(enum) { dont_care, bits: u31 } = null,
    accum_alpha_bits: ?union(enum) { dont_care, bits: u31 } = null,
    aux_buffers: ?union(enum) { dont_care, n: u31 } = null,
    samples: ?union(enum) { dont_care, n: u31 } = null,
    refresh_rate: ?union(enum) { dont_care, fps: u31 } = null,
    stereo: ?bool = null,
    srgb_capable: ?bool = null,
    doublebuffer: ?bool = null,
    client_api: ?ClientApi = null,
    context_creation_api: ?CreationApi = null,
    context_version_major: ?u8 = null,
    context_version_minor: ?u8 = null,
    context_robustness: ?Robustness = null,
    context_release_behavior: ?ReleaseBehavior = null,
    opengl_forward_compat: ?bool = null,
    context_debug: ?bool = null,
    opengl_profile: ?Profile = null,
    win32_keyboard_menu: ?bool = null,
    win32_showdefault: ?bool = null,
    cocoa_graphics_switching: ?bool = null,
    cocoa_frame_name: ?[]const u8 = null,
    wayland_app_id: ?[]const u8 = null,
    x11_class_name: ?[]const u8 = null,
    x11_instance_name: ?[]const u8 = null,
};

inline fn b(v: bool) @TypeOf(glfw.TRUE) {
    return switch (v) {
        true => glfw.TRUE,
        false => glfw.FALSE,
    };
}

fn windowHint(hint: Hint) void {
    glfw.defaultWindowHints();
    if (hint.resizable) |resizable| {
        glfw.windowHint(glfw.RESIZABLE, b(resizable));
    }
    if (hint.visible) |visible| {
        glfw.windowHint(glfw.VISIBLE, b(visible));
    }
    if (hint.decorated) |decorated| {
        glfw.windowHint(glfw.DECORATED, b(decorated));
    }
    if (hint.focused) |focused| {
        glfw.windowHint(glfw.FOCUSED, b(focused));
    }
    if (hint.auto_iconify) |auto_iconify| {
        glfw.windowHint(glfw.AUTO_ICONIFY, b(auto_iconify));
    }
    if (hint.floating) |floating| {
        glfw.windowHint(glfw.FLOATING, b(floating));
    }
    if (hint.maximized) |maximized| {
        glfw.windowHint(glfw.MAXIMIZED, b(maximized));
    }
    if (hint.center_cursor) |center_cursor| {
        glfw.windowHint(glfw.CENTER_CURSOR, b(center_cursor));
    }
    if (hint.transparent_framebuffer) |transparent_framebuffer| {
        glfw.windowHint(glfw.TRANSPARENT_FRAMEBUFFER, b(transparent_framebuffer));
    }
    if (hint.focus_on_show) |focus_on_show| {
        glfw.windowHint(glfw.FOCUS_ON_SHOW, b(focus_on_show));
    }
    if (hint.scale_to_monitor) |scale_to_monitor| {
        glfw.windowHint(glfw.SCALE_TO_MONITOR, b(scale_to_monitor));
    }
    if (hint.scale_framebuffer) |scale_framebuffer| {
        glfw.windowHint(glfw.SCALE_FRAMEBUFFER, b(scale_framebuffer));
    }
    if (hint.mouse_passthrough) |mouse_passthrough| {
        glfw.windowHint(glfw.MOUSE_PASSTHROUGH, b(mouse_passthrough));
    }
    if (hint.stereo) |stereo| {
        glfw.windowHint(glfw.STEREO, b(stereo));
    }
    if (hint.srgb_capable) |srgb_capable| {
        glfw.windowHint(glfw.SRGB_CAPABLE, b(srgb_capable));
    }
    if (hint.doublebuffer) |doublebuffer| {
        glfw.windowHint(glfw.DOUBLEBUFFER, b(doublebuffer));
    }
    if (hint.win32_keyboard_menu) |win32_keyboard_menu| {
        glfw.windowHint(glfw.WIN32_KEYBOARD_MENU, b(win32_keyboard_menu));
    }
    if (hint.win32_showdefault) |win32_showdefault| {
        glfw.windowHint(glfw.WIN32_SHOWDEFAULT, b(win32_showdefault));
    }
    if (hint.cocoa_graphics_switching) |cocoa_graphics_switching| {
        glfw.windowHint(glfw.COCOA_GRAPHICS_SWITCHING, b(cocoa_graphics_switching));
    }
    if (hint.opengl_forward_compat) |opengl_forward_compat| {
        glfw.windowHint(glfw.OPENGL_FORWARD_COMPAT, b(opengl_forward_compat));
    }
    if (hint.context_debug) |context_debug| {
        glfw.windowHint(glfw.CONTEXT_DEBUG, b(context_debug));
    }

    if (hint.position_x) |position_x| {
        const value = switch (position_x) {
            .any => glfw.ANY_POSITION,
            .pos => |pos| @as(c_int, @intCast(pos)),
        };
        glfw.windowHint(glfw.POSITION_X, value);
    }
    if (hint.position_y) |position_y| {
        const value = switch (position_y) {
            .any => glfw.ANY_POSITION,
            .pos => |pos| @as(c_int, @intCast(pos)),
        };
        glfw.windowHint(glfw.POSITION_Y, value);
    }

    if (hint.red_bits) |red_bits| {
        const value = switch (red_bits) {
            .dont_care => glfw.DONT_CARE,
            .bits => |bits| @as(c_int, @intCast(bits)),
        };
        glfw.windowHint(glfw.RED_BITS, value);
    }
    if (hint.green_bits) |green_bits| {
        const value = switch (green_bits) {
            .dont_care => glfw.DONT_CARE,
            .bits => |bits| @as(c_int, @intCast(bits)),
        };
        glfw.windowHint(glfw.GREEN_BITSRED_BITS, value);
    }
    if (hint.blue_bits) |blue_bits| {
        const value = switch (blue_bits) {
            .dont_care => glfw.DONT_CARE,
            .bits => |bits| @as(c_int, @intCast(bits)),
        };
        glfw.windowHint(glfw.BLUE_BITSRED_BITS, value);
    }
    if (hint.alpha_bits) |alpha_bits| {
        const value = switch (alpha_bits) {
            .dont_care => glfw.DONT_CARE,
            .bits => |bits| @as(c_int, @intCast(bits)),
        };
        glfw.windowHint(glfw.ALPHA_BITSRED_BITS, value);
    }
    if (hint.depth_bits) |depth_bits| {
        const value = switch (depth_bits) {
            .dont_care => glfw.DONT_CARE,
            .bits => |bits| @as(c_int, @intCast(bits)),
        };
        glfw.windowHint(glfw.DEPTH_BITSRED_BITS, value);
    }
    if (hint.stencil_bits) |stencil_bits| {
        const value = switch (stencil_bits) {
            .dont_care => glfw.DONT_CARE,
            .bits => |bits| @as(c_int, @intCast(bits)),
        };
        glfw.windowHint(glfw.STENCIL_BITSRED_BITS, value);
    }
    if (hint.accum_red_bits) |accum_red_bits| {
        const value = switch (accum_red_bits) {
            .dont_care => glfw.DONT_CARE,
            .bits => |bits| @as(c_int, @intCast(bits)),
        };
        glfw.windowHint(glfw.ACCUM_RED_BITS, value);
    }
    if (hint.accum_green_bits) |accum_green_bits| {
        const value = switch (accum_green_bits) {
            .dont_care => glfw.DONT_CARE,
            .bits => |bits| @as(c_int, @intCast(bits)),
        };
        glfw.windowHint(glfw.ACCUM_GREEN_BITS, value);
    }
    if (hint.accum_blue_bits) |accum_blue_bits| {
        const value = switch (accum_blue_bits) {
            .dont_care => glfw.DONT_CARE,
            .bits => |bits| @as(c_int, @intCast(bits)),
        };
        glfw.windowHint(glfw.ACCUM_BLUE_BITS, value);
    }
    if (hint.accum_alpha_bits) |accum_alpha_bits| {
        const value = switch (accum_alpha_bits) {
            .dont_care => glfw.DONT_CARE,
            .bits => |bits| @as(c_int, @intCast(bits)),
        };
        glfw.windowHint(glfw.ACCUM_ALPHA_BITS, value);
    }
    if (hint.aux_buffers) |aux_buffers| {
        const value = switch (aux_buffers) {
            .dont_care => glfw.DONT_CARE,
            .n => |n| @as(c_int, @intCast(n)),
        };
        glfw.windowHint(glfw.AUX_BUFFERS, value);
    }
    if (hint.samples) |samples| {
        const value = switch (samples) {
            .dont_care => glfw.DONT_CARE,
            .n => |n| @as(c_int, @intCast(n)),
        };
        glfw.windowHint(glfw.SAMPLES, value);
    }
    if (hint.refresh_rate) |refresh_rate| {
        const value = switch (refresh_rate) {
            .dont_care => glfw.DONT_CARE,
            .fps => |fps| @as(c_int, @intCast(fps)),
        };
        glfw.windowHint(glfw.REFRESH_RATE, value);
    }
    if (hint.client_api) |client_api| {
        glfw.windowHint(glfw.CLIENT_API, @intFromEnum(client_api));
    }
    if (hint.context_creation_api) |context_creation_api| {
        glfw.windowHint(glfw.CLIENT_API, @intFromEnum(context_creation_api));
    }
    if (hint.context_version_major) |context_version_major| {
        glfw.windowHint(glfw.CONTEXT_VERSION_MAJOR, @ptrCast(context_version_major));
    }
    if (hint.context_version_minor) |context_version_minor| {
        glfw.windowHint(glfw.CONTEXT_VERSION_MINOR, @ptrCast(context_version_minor));
    }
    if (hint.context_robustness) |context_robustness| {
        glfw.windowHint(glfw.CONTEXT_ROBUSTNESS, @intFromEnum(context_robustness));
    }
    if (hint.context_release_behavior) |context_release_behavior| {
        glfw.windowHint(glfw.CONTEXT_RELEASE_BEHAVIOR, @intFromEnum(context_release_behavior));
    }
    if (hint.opengl_profile) |opengl_profile| {
        glfw.windowHint(glfw.OPENGL_PROFILE, @intFromEnum(opengl_profile));
    }
    if (hint.cocoa_frame_name) |cocoa_frame_name| {
        glfw.windowHintString(glfw.COCOA_FRAME_NAME, @ptrCast(cocoa_frame_name));
    }
    if (hint.wayland_app_id) |wayland_app_id| {
        glfw.windowHintString(glfw.WAYLAND_APP_ID, @ptrCast(wayland_app_id));
    }
    if (hint.x11_class_name) |x11_class_name| {
        glfw.windowHintString(glfw.X11_CLASS_NAME, @ptrCast(x11_class_name));
    }
    if (hint.x11_instance_name) |x11_instance_name| {
        glfw.windowHintString(glfw.X11_INSTANCE_NAME, @ptrCast(x11_instance_name));
    }
}

pub const WindowError = error{
    InvalidValue,
    ApiUnavailable,
    VersionUnavailable,
    FormatUnavailable,
    NoWindowContext,
};

pub fn create(width: u32, height: u32, title: []const u8, hint: Hint) WindowError!Window {
    const monitor = if (hint.monitor) |monitor| monitor.impl else null;
    const share = if (hint.share) |share| share.impl else null;

    const impl = glfw.createWindow(
        @intCast(width),
        @intCast(height),
        @ptrCast(title),
        monitor,
        share,
    );
    if (impl == null) {
        @branchHint(.cold);
        glfw.check() catch |err| switch (err) {
            error.InvalidValue,
            error.ApiUnavailable,
            error.VersionUnavailable,
            error.FormatUnavailable,
            error.NoWindowContext,
            => return @errorCast(err),
            else => unreachable,
        };
        unreachable;
    }
    return .{ .impl = impl.? };
}

pub fn destroy(self: *Window) void {
    glfw.destroyWindow(self.impl);
}

pub fn swapBuffer(self: *Window) void {
    glfw.swapBuffers(self.impl);
}

pub fn makeContextCurrent(self: *Window) void {
    glfw.makeContextCurrent(self.impl);
}

pub fn shouldClose(self: *const Window) bool {
    return glfw.windowShouldClose(self.impl) == glfw.TRUE;
}

pub fn setShouldClose(self: *Window, value: bool) void {
    glfw.setWindowShouldClose(self.impl, b(value));
}

pub fn getTitle(self: *const Window) []const u8 {
    const title = glfw.getWindowTitle(self.impl);
    if (title == null) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
        unreachable;
    }
    return title[0..std.mem.len(title)];
}

pub fn setTitle(self: *Window, title: []const u8) void {
    glfw.setWindowTitle(self.impl, @ptrCast(title));
}

pub fn iconify(self: *Window) void {
    glfw.iconifyWindow(self.impl);
}

pub fn restore(self: *Window) void {
    glfw.restoreWindow(self.impl);
}

pub fn maximize(self: *Window) void {
    glfw.maximizeWindow(self.impl);
}

pub fn show(self: *Window) void {
    glfw.showWindow(self.impl);
}

pub fn hide(self: *Window) void {
    glfw.hideWindow(self.impl);
}

pub fn focus(self: *Window) void {
    glfw.focusWindow(self.impl);
}

pub fn requestAttention(self: *Window) void {
    glfw.requestWindowAttention(self.impl);
}

const Pos = types.Pos;

pub fn getPos(self: *const Window) error{FeatureUnavailable}!Pos {
    var x: c_int = undefined;
    var y: c_int = undefined;
    glfw.getWindowPos(self.impl, &x, &y);
    if (x == 0 and y == 0) {
        @branchHint(.cold);
        glfw.check() catch |err| switch (err) {
            error.FeatureUnavailable,
            => return @errorCast(err),
            else => unreachable,
        };
    }
    return .{ .x = @intCast(x), .y = @intCast(y) };
}

pub fn setPos(self: *Window, x: i32, y: i32) void {
    glfw.setWindowPos(self.impl, @intCast(x), @intCast(y));
}

const Size = types.Size;

pub fn getSize(self: *const Window) Size {
    var width: c_int = undefined;
    var height: c_int = undefined;
    glfw.getWindowSize(self.impl, &width, &height);
    if (width == 0 and height == 0) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
    }
    return .{
        .width = @intCast(width),
        .height = @intCast(height),
    };
}

pub fn setSize(self: *Window, width: u32, height: u32) void {
    glfw.setWindowSize(self.impl, @intCast(width), @intCast(height));
}

pub fn setSizeLimits(self: *Window, min_width: ?u32, min_height: ?u32, max_width: ?u32, max_height: ?u32) void {
    glfw.setWindowSizeLimits(
        self.impl,
        min_width orelse glfw.DONT_CARE,
        min_height orelse glfw.DONT_CARE,
        max_width orelse glfw.DONT_CARE,
        max_height orelse glfw.DONT_CARE,
    );
}

pub fn setAspectRatio(self: *Window, numer: ?u32, denom: ?u32) void {
    glfw.setWindowAspectRatio(
        self.impl,
        numer orelse glfw.DONT_CARE,
        denom orelse glfw.DONT_CARE,
    );
}

pub fn getFrameBufferSize(self: *const Window) Size {
    var width: c_int = undefined;
    var height: c_int = undefined;
    glfw.getFramebufferSize(self.impl, &width, &height);
    if (width == 0 and height == 0) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
    }
    return .{
        .width = @intCast(width),
        .height = @intCast(height),
    };
}

pub fn getFrameSize(self: *const Window) Rectangle {
    var left: c_int = undefined;
    var top: c_int = undefined;
    var right: c_int = undefined;
    var bottom: c_int = undefined;
    glfw.getWindowFrameSize(self.impl, &left, &top, &right, &bottom);
    if (left == 0 and top == 0 and right == 0 and bottom == 0) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
    }
    return .{
        .left = @intCast(left),
        .right = @intCast(right),
        .top = @intCast(top),
        .bottom = @intCast(bottom),
    };
}

pub fn getOpacity(self: *const Window) f32 {
    return glfw.getWindowOpacity(self.impl);
}

pub fn setOpacity(self: *Window, opacity: f32) void {
    glfw.setWindowOpacity(self.impl, opacity);
}

pub fn getMonitor(self: *const Window) ?Monitor {
    const monitor = glfw.getWindowMonitor(self.impl);
    if (monitor == null) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
        return null;
    }
    return .{ .impl = monitor.? };
}

pub fn setMonitor(self: *Window, monitor: ?Monitor, x: i32, y: i32, width: u32, height: u32, fps: ?u32) void {
    glfw.setWindowMonitor(
        self.impl,
        if (monitor) |m| m.impl else null,
        @intCast(x),
        @intCast(y),
        @intCast(width),
        @intCast(height),
        if (fps) |f| @intCast(f) else null,
    );
}

pub const Attrib = enum {
    focused,
    iconified,
    maximized,
    hovered,
    visible,
    resizable,
    decorated,
    auto_iconify,
    floating,
    transparent_framebuffer,
    focus_on_show,
    mouse_passthrough,
    context_no_error,
    opengl_forward_compat,
    context_debug,
    doublebuffer,
    client_api,
    context_creation_api,
    context_version_major,
    context_version_minor,
    context_revision,
    opengl_profile,
    context_release_behavior,
    context_robustness,
};

pub const AttribData = union(Attrib) {
    focused: bool,
    iconified: bool,
    maximized: bool,
    hovered: bool,
    visible: bool,
    resizable: bool,
    decorated: bool,
    auto_iconify: bool,
    floating: bool,
    transparent_framebuffer: bool,
    focus_on_show: bool,
    mouse_passthrough: bool,
    context_no_error: bool,
    opengl_forward_compat: bool,
    context_debug: bool,
    doublebuffer: bool,
    context_version_major: u8,
    context_version_minor: u8,
    context_revision: u8,
    client_api: ClientApi,
    context_creation_api: CreationApi,
    opengl_profile: Profile,
    context_release_behavior: ReleaseBehavior,
    context_robustness: Robustness,
};

inline fn attr(attrib: Attrib) c_int {
    return switch (attrib) {
        .focused => glfw.FOCUSED,
        .iconified => glfw.ICONIFIED,
        .maximized => glfw.MAXIMIZED,
        .hovered => glfw.HOVERED,
        .visible => glfw.VISIBLE,
        .resizable => glfw.RESIZABLE,
        .decorated => glfw.DECORATED,
        .auto_iconify => glfw.AUTO_ICONIFY,
        .floating => glfw.FLOATING,
        .transparent_framebuffer => glfw.TRANSPARENT_FRAMEBUFFER,
        .focus_on_show => glfw.FOCUS_ON_SHOW,
        .mouse_passthrough => glfw.MOUSE_PASSTHROUGH,
        .context_no_error => glfw.CONTEXT_NO_ERROR,
        .opengl_forward_compat => glfw.OPENGL_FORWARD_COMPAT,
        .context_debug => glfw.CONTEXT_DEBUG,
        .doublebuffer => glfw.DOUBLEBUFFER,
        .client_api => glfw.CLIENT_API,
        .context_creation_api => glfw.CONTEXT_CREATION_API,
        .context_version_major => glfw.CONTEXT_VERSION_MAJOR,
        .context_version_minor => glfw.CONTEXT_VERSION_MINOR,
        .context_revision => glfw.CONTEXT_REVISION,
        .opengl_profile => glfw.OPENGL_PROFILE,
        .context_release_behavior => glfw.CONTEXT_RELEASE_BEHAVIOR,
        .context_robustness => glfw.CONTEXT_ROBUSTNESS,
    };
}

pub fn getAttrib(self: *const Window, attrib: Attrib) AttribData {
    const data = glfw.getWindowAttrib(self.impl, attr(attrib));
    switch (data) {
        glfw.FOCUSED => |d| return .{ .focused = d == glfw.TRUE },
        glfw.ICONIFIED => |d| return .{ .iconified = d == glfw.TRUE },
        glfw.MAXIMIZED => |d| return .{ .maximized = d == glfw.TRUE },
        glfw.HOVERED => |d| return .{ .hovered = d == glfw.TRUE },
        glfw.VISIBLE => |d| return .{ .visible = d == glfw.TRUE },
        glfw.RESIZABLE => |d| return .{ .resizable = d == glfw.TRUE },
        glfw.DECORATED => |d| return .{ .decorated = d == glfw.TRUE },
        glfw.AUTO_ICONIFY => |d| return .{ .auto_iconify = d == glfw.TRUE },
        glfw.FLOATING => |d| return .{ .floating = d == glfw.TRUE },
        glfw.TRANSPARENT_FRAMEBUFFER => |d| return .{ .transparent_framebuffer = d == glfw.TRUE },
        glfw.FOCUS_ON_SHOW => |d| return .{ .focus_on_show = d == glfw.TRUE },
        glfw.MOUSE_PASSTHROUGH => |d| return .{ .mouse_passthrough = d == glfw.TRUE },
        glfw.CONTEXT_NO_ERROR => |d| return .{ .context_no_error = d == glfw.TRUE },
        glfw.OPENGL_FORWARD_COMPAT => |d| return .{ .opengl_forward_compat = d == glfw.TRUE },
        glfw.CONTEXT_DEBUG => |d| return .{ .context_debug = d == glfw.TRUE },
        glfw.DOUBLEBUFFER => |d| return .{ .doublebuffer = d == glfw.TRUE },

        glfw.CONTEXT_VERSION_MAJOR => |d| return .{ .context_version_major = @intCast(d) },
        glfw.CONTEXT_VERSION_MINOR => |d| return .{ .context_version_minor = @intCast(d) },
        glfw.CONTEXT_REVISION => |d| return .{ .context_revision = @intCast(d) },

        glfw.CLIENT_API => |e| return .{ .client_api = @enumFromInt(e) },
        glfw.CONTEXT_CREATION_API => |e| return .{ .context_creation_api = @enumFromInt(e) },
        glfw.OPENGL_PROFILE => |e| return .{ .opengl_profile = @enumFromInt(e) },
        glfw.CONTEXT_RELEASE_BEHAVIOR => |e| return .{ .context_release_behavior = @enumFromInt(e) },
        glfw.CONTEXT_ROBUSTNESS => |e| return .{ .context_robustness = @enumFromInt(e) },
        0 => {
            @branchHint(.cold);
            glfw.check() catch unreachable;
            unreachable;
        },
        else => unreachable,
    }
}

pub const SetAttribType = enum(c_int) {
    decorated = glfw.DECORATED,
    resizable = glfw.RESIZABLE,
    floating = glfw.FLOATING,
    auto_iconify = glfw.AUTO_ICONIFY,
    focus_on_show = glfw.FOCUS_ON_SHOW,
    mouse_passthrough = glfw.MOUSE_PASSTHROUGH,
};

pub const SetAttrib = union(SetAttribType) {
    decorated: bool,
    resizable: bool,
    floating: bool,
    auto_iconify: bool,
    focus_on_show: bool,
    mouse_passthrough: bool,
};

pub fn setAttrib(self: *Window, attrib: SetAttrib) void {
    switch (attrib) {
        inline else => |a| {
            glfw.setWindowAttrib(self.impl, @intFromEnum(attrib), a);
        },
    }
}

pub fn setIcon(self: *Window, allocator: Allocator, images: []Image) error{
    InvalidValue,
    FeatureUnavailable,
}!void {
    var glfw_images = try allocator.alloc(glfw.Image, images.len);
    defer allocator.free(glfw_images);
    for (0..glfw_images.len) |i| {
        glfw_images[i] = glfw.Image{
            .width = images[i].width,
            .height = images[i].height,
            .pixels = @ptrCast(images[i].pixels),
        };
    }
    glfw.check() catch |err| switch (err) {
        error.InvalidValue,
        error.FeatureUnavailable,
        => return @errorCast(err),
        else => unreachable,
    };
    glfw.setWindowIcon(self.impl, glfw_images.len, @ptrCast(glfw_images));
}

pub fn getInputMode(self: *const Window, mode: ModeType) Mode {
    const glfw_mode = glfw.getInputMode(self.impl, @intFromEnum(mode));
    switch (glfw_mode) {
        .cursor => return @enumFromInt(glfw_mode),
        else => return glfw_mode == glfw.TRUE,
    }
}

pub fn setInputMode(self: *Window, mode: Mode) void {
    const value = switch (mode) {
        .cursor => |m| @intFromEnum(m),
        inline else => |a| if (a) glfw.TRUE else glfw.FALSE,
    };
    glfw.setInputMode(self.impl, @intFromEnum(mode), value);
}

pub fn getKey(self: *const Window, key: Key) State {
    return @enumFromInt(glfw.getKey(self.impl, @intFromEnum(key)));
}

pub fn getMouseButton(self: *const Window, button: Button) State {
    return @enumFromInt(glfw.getMouseButton(self.impl, @intFromEnum(button)));
}

const fPos = types.f64Pos;

pub fn getCursorPos(self: *const Window) error{}!fPos {
    var x: f64 = undefined;
    var y: f64 = undefined;
    glfw.getCursorPos(self.impl, &x, &y);
    if (x == 0 and y == 0) {
        glfw.check() catch |err| switch (err) {
            error.PlatformError => return @errorCast(err),
            else => unreachable,
        };
    }
    return .{ .x = x, .y = y };
}

pub fn setCursorPos(self: *Window, x: f32, y: f32) void {
    glfw.setCursorPos(self.impl, x, y);
}

pub fn setCursor(self: *Window, cursor: ?Cursor) void {
    glfw.setCursor(self.impl, if (cursor) |c| c.impl else null);
}

pub fn getCurrentContext() ?Window {
    const window = glfw.getCurrentContext();
    if (window == null) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
        return null;
    }
    const ptr = glfw.getWindowUserPointer(window);
    if (ptr == null) {
        return .{ .impl = window.?, .event = .{} };
    }
    return @as(*Window, @ptrCast(ptr.?)).*;
}

pub fn setHandle(self: *Window, handle_impl: Handle, config: Handle.EventConfig) void {
    self.handle_impl = handle_impl;
    Handle.enable_callback(self, config);
}
