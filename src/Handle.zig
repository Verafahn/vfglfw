const Handle = @This();
const glfw = @import("glfw3");
const Window = @import("Window.zig");
const input = @import("input.zig");
const Key = input.Key;
const Action = input.Action;
const Modify = input.Modify;
const Button = input.MouseButton;
const std = @import("std");

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
    frame_buffer_size: struct { width: i32, height: i32 },
    content_sacle: struct { x: f32, y: f32 },
    key: struct {
        key: Key,
        scancode: u32,
        action: Action,
        mods: Modify,
    },
    char: u32,
    char_mods: struct {
        char: u32,
        mods: Modify,
    },
    mouse_button: struct {
        button: Button,
        action: Action,
        mods: Modify,
    },
    cursor_pos: struct { x: f64, y: f64 },
    cursor_enter: bool,
    scroll: struct { x: f64, y: f64 },
    drop: []const []const u8,
};

pub const EventConfig = struct {
    pos: bool = false,
    size: bool = false,
    close: bool = false,
    refresh: bool = false,
    focus: bool = false,
    iconify: bool = false,
    maximize: bool = false,
    frame_buffer_size: bool = false,
    content_sacle: bool = false,
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

pub fn enable_callback(self: *Window, config: EventConfig) void {
    glfw.setWindowUserPointer(self.impl, self);
    if (config.pos)
        _ = glfw.setWindowPosCallback(self.impl, &when_pos);
    if (config.size)
        _ = glfw.setWindowSizeCallback(self.impl, &when_size);
    if (config.close)
        _ = glfw.setWindowCloseCallback(self.impl, &when_close);
    if (config.refresh)
        _ = glfw.setWindowRefreshCallback(self.impl, &when_refresh);
    if (config.focus)
        _ = glfw.setWindowFocusCallback(self.impl, &when_focus);
    if (config.iconify)
        _ = glfw.setWindowIconifyCallback(self.impl, &when_iconify);
    if (config.maximize)
        _ = glfw.setWindowMaximizeCallback(self.impl, &when_maximize);
    if (config.frame_buffer_size)
        _ = glfw.setFramebufferSizeCallback(self.impl, &when_frame_buffer_size);
    if (config.content_sacle)
        _ = glfw.setWindowContentScaleCallback(self.impl, &when_content_sacle);

    if (config.key)
        _ = glfw.setKeyCallback(self.impl, &when_key);
    if (config.char)
        _ = glfw.setCharCallback(self.impl, &when_char);
    if (config.char_mods)
        _ = glfw.setCharModsCallback(self.impl, &when_char_mods);
    if (config.mouse_button)
        _ = glfw.setMouseButtonCallback(self.impl, &when_mouse_button);
    if (config.cursor_pos)
        _ = glfw.setCursorPosCallback(self.impl, &when_cursor_pos);
    if (config.cursor_enter)
        _ = glfw.setCursorEnterCallback(self.impl, &when_cursor_enter);
    if (config.scroll)
        _ = glfw.setScrollCallback(self.impl, &when_scroll);
    if (config.drop)
        _ = glfw.setDropCallback(self.impl, &when_drop);
}

fn when_key(this: ?*glfw.Window, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{ .key = .{
            .key = @enumFromInt(key),
            .scancode = @intCast(scancode),
            .action = @enumFromInt(action),
            .mods = @bitCast(@as(u6, @intCast(mods))),
        } });
    }
}
fn when_char(this: ?*glfw.Window, char: c_uint) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .char = @intCast(char),
        });
    }
}
fn when_char_mods(this: ?*glfw.Window, char: c_uint, mods: c_int) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .char_mods = .{
                .char = @intCast(char),
                .mods = @bitCast(@as(u6, @intCast(mods))),
            },
        });
    }
}
fn when_mouse_button(this: ?*glfw.Window, button: c_int, action: c_int, mods: c_int) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .mouse_button = .{
                .button = @enumFromInt(button),
                .action = @enumFromInt(action),
                .mods = @bitCast(@as(u6, @intCast(mods))),
            },
        });
    }
}
fn when_cursor_pos(this: ?*glfw.Window, x: f64, y: f64) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .cursor_pos = .{
                .x = x,
                .y = y,
            },
        });
    }
}
fn when_cursor_enter(this: ?*glfw.Window, a: c_int) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .cursor_enter = a == glfw.TRUE,
        });
    }
}
fn when_scroll(this: ?*glfw.Window, xs: f64, ys: f64) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .scroll = .{
                .x = xs,
                .y = ys,
            },
        });
    }
}
fn when_drop(this: ?*glfw.Window, count: c_int, path: [*c][*c]const u8) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        if (count == 0) {
            handle.vtable.handle(self.handle_impl.?.vptr, .{ .drop = &.{} });
        }
        var buffer: [16 * 1024]u8 = undefined;
        var fixed_allocator = std.heap.FixedBufferAllocator.init(&buffer);
        const allocator = fixed_allocator.allocator();

        var paths = allocator.alloc([]u8, @intCast(count)) catch unreachable;
        for (0..@intCast(count)) |i| {
            const len = std.mem.len(path[i]);
            paths[i] = allocator.alloc(u8, len) catch unreachable;
            std.mem.copyForwards(u8, paths[i], path[i][0..len]);
        }

        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .drop = paths,
        });
    }
}

fn when_pos(this: ?*glfw.Window, x: c_int, y: c_int) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .pos = .{
                .x = x,
                .y = y,
            },
        });
    }
}

fn when_size(this: ?*glfw.Window, width: c_int, height: c_int) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .size = .{
                .height = height,
                .width = width,
            },
        });
    }
}

fn when_close(this: ?*glfw.Window) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .close);
    }
}

fn when_refresh(this: ?*glfw.Window) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .refresh);
    }
}

fn when_focus(this: ?*glfw.Window, f: c_int) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .focus = f == glfw.TRUE,
        });
    }
}

fn when_iconify(this: ?*glfw.Window, i: c_int) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .iconify = i == glfw.TRUE,
        });
    }
}

fn when_maximize(this: ?*glfw.Window, m: c_int) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .maximize = m == glfw.TRUE,
        });
    }
}

fn when_frame_buffer_size(this: ?*glfw.Window, width: c_int, height: c_int) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .frame_buffer_size = .{
                .height = height,
                .width = width,
            },
        });
    }
}

fn when_content_sacle(this: ?*glfw.Window, xs: f32, ys: f32) callconv(.c) void {
    const self: *Window = @ptrCast(@alignCast(glfw.getWindowUserPointer(this)));
    if (self.handle_impl) |handle| {
        handle.vtable.handle(self.handle_impl.?.vptr, .{
            .content_sacle = .{
                .x = xs,
                .y = ys,
            },
        });
    }
}
