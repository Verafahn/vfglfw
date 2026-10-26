const Handle = @This();
const glfw = @import("glfw3");
const input = @import("input.zig");
const std = @import("std");

const Key = input.Key;
const Action = input.Action;
const Modifiers = input.Modifiers;
const Button = input.MouseButton;

vptr: *anyopaque,
vtable: VTable,

pub const Event = union(enum) {
    pos: struct { x: i32, y: i32 },
    size: struct { width: i32, height: i32 },
    close,
    refresh,
    focus: bool,
    iconify: bool,
    maximize: bool,
    framebuffer_size: struct { width: i32, height: i32 },
    content_scale: struct { x: f32, y: f32 },
    key: struct {
        key: Key,
        scancode: i32,
        action: Action,
        mods: Modifiers,
    },
    char: u32,
    char_mods: struct {
        char: u32,
        mods: Modifiers,
    },
    mouse_button: struct {
        button: Button,
        action: Action,
        mods: Modifiers,
    },
    cursor_pos: struct { x: f64, y: f64 },
    cursor_enter: bool,
    scroll: struct { x: f64, y: f64 },
    /// The slices are only valid for the duration of the callback.
    drop: []const [:0]const u8,
};

pub const EventConfig = struct {
    pos: bool = false,
    size: bool = false,
    close: bool = false,
    refresh: bool = false,
    focus: bool = false,
    iconify: bool = false,
    maximize: bool = false,
    framebuffer_size: bool = false,
    content_scale: bool = false,
    key: bool = false,
    char: bool = false,
    char_mods: bool = false,
    mouse_button: bool = false,
    cursor_pos: bool = false,
    cursor_enter: bool = false,
    scroll: bool = false,
    drop: bool = false,
};

pub const VTable = struct {
    handle: *const fn (*anyopaque, event: Event) void,
};

fn getHandle(window: ?*glfw.Window) ?*Handle {
    const ptr = glfw.getWindowUserPointer(window) orelse return null;
    return @ptrCast(@alignCast(ptr));
}

fn modifiers(mods: c_int) Modifiers {
    return @bitCast(@as(u6, @truncate(@as(u32, @bitCast(mods)))));
}

/// Replaces all window callbacks according to `config`. Callbacks not enabled
/// in `config` are removed, so calling this again fully reconfigures the
/// window instead of accumulating subscriptions.
pub fn enable_callbacks(impl: *glfw.Window, config: EventConfig) void {
    _ = glfw.setWindowPosCallback(impl, if (config.pos) &when_pos else null);
    _ = glfw.setWindowSizeCallback(impl, if (config.size) &when_size else null);
    _ = glfw.setWindowCloseCallback(impl, if (config.close) &when_close else null);
    _ = glfw.setWindowRefreshCallback(impl, if (config.refresh) &when_refresh else null);
    _ = glfw.setWindowFocusCallback(impl, if (config.focus) &when_focus else null);
    _ = glfw.setWindowIconifyCallback(impl, if (config.iconify) &when_iconify else null);
    _ = glfw.setWindowMaximizeCallback(impl, if (config.maximize) &when_maximize else null);
    _ = glfw.setFramebufferSizeCallback(impl, if (config.framebuffer_size) &when_framebuffer_size else null);
    _ = glfw.setWindowContentScaleCallback(impl, if (config.content_scale) &when_content_scale else null);

    _ = glfw.setKeyCallback(impl, if (config.key) &when_key else null);
    _ = glfw.setCharCallback(impl, if (config.char) &when_char else null);
    _ = glfw.setCharModsCallback(impl, if (config.char_mods) &when_char_mods else null);
    _ = glfw.setMouseButtonCallback(impl, if (config.mouse_button) &when_mouse_button else null);
    _ = glfw.setCursorPosCallback(impl, if (config.cursor_pos) &when_cursor_pos else null);
    _ = glfw.setCursorEnterCallback(impl, if (config.cursor_enter) &when_cursor_enter else null);
    _ = glfw.setScrollCallback(impl, if (config.scroll) &when_scroll else null);
    _ = glfw.setDropCallback(impl, if (config.drop) &when_drop else null);
}

fn when_key(this: ?*glfw.Window, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .key = .{
        .key = @fromBackingInt(@intCast(key)),
        .scancode = scancode,
        .action = @fromBackingInt(@intCast(action)),
        .mods = modifiers(mods),
    } });
}

fn when_char(this: ?*glfw.Window, char: c_uint) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .char = @intCast(char) });
}

fn when_char_mods(this: ?*glfw.Window, char: c_uint, mods: c_int) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{
        .char_mods = .{
            .char = @intCast(char),
            .mods = modifiers(mods),
        },
    });
}

fn when_mouse_button(this: ?*glfw.Window, button: c_int, action: c_int, mods: c_int) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{
        .mouse_button = .{
            .button = @fromBackingInt(@intCast(button)),
            .action = @fromBackingInt(@intCast(action)),
            .mods = modifiers(mods),
        },
    });
}

fn when_cursor_pos(this: ?*glfw.Window, x: f64, y: f64) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .cursor_pos = .{ .x = x, .y = y } });
}

fn when_cursor_enter(this: ?*glfw.Window, a: c_int) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .cursor_enter = a == glfw.TRUE });
}

fn when_scroll(this: ?*glfw.Window, xs: f64, ys: f64) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .scroll = .{ .x = xs, .y = ys } });
}

fn when_drop(this: ?*glfw.Window, count: c_int, paths: [*c][*c]const u8) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    if (count == 0) {
        handle.vtable.handle(handle.vptr, .{ .drop = &.{} });
        return;
    }

    const n: usize = @intCast(count);
    const slices = std.heap.page_allocator.alloc([:0]const u8, n) catch return;
    defer std.heap.page_allocator.free(slices);

    for (0..n) |i| {
        const len = std.mem.len(paths[i]);
        slices[i] = paths[i][0..len :0];
    }

    handle.vtable.handle(handle.vptr, .{ .drop = slices });
}

fn when_pos(this: ?*glfw.Window, x: c_int, y: c_int) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .pos = .{ .x = x, .y = y } });
}

fn when_size(this: ?*glfw.Window, width: c_int, height: c_int) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .size = .{ .width = width, .height = height } });
}

fn when_close(this: ?*glfw.Window) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .close);
}

fn when_refresh(this: ?*glfw.Window) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .refresh);
}

fn when_focus(this: ?*glfw.Window, f: c_int) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .focus = f == glfw.TRUE });
}

fn when_iconify(this: ?*glfw.Window, i: c_int) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .iconify = i == glfw.TRUE });
}

fn when_maximize(this: ?*glfw.Window, m: c_int) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .maximize = m == glfw.TRUE });
}

fn when_framebuffer_size(this: ?*glfw.Window, width: c_int, height: c_int) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .framebuffer_size = .{
        .width = width,
        .height = height,
    } });
}

fn when_content_scale(this: ?*glfw.Window, xs: f32, ys: f32) callconv(.c) void {
    const handle = getHandle(this) orelse return;
    handle.vtable.handle(handle.vptr, .{ .content_scale = .{ .x = xs, .y = ys } });
}
