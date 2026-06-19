const glfw = @import("glfw3");
const std = @import("std");
const Allocator = std.mem.Allocator;
const input = @This();

pub const Key = enum(c_int) {
    space = glfw.KEY_SPACE,
    apostrophe = glfw.KEY_APOSTROPHE,
    comma = glfw.KEY_COMMA,
    minus = glfw.KEY_MINUS,
    period = glfw.KEY_PERIOD,
    slash = glfw.KEY_SLASH,
    @"0" = glfw.KEY_0,
    @"1" = glfw.KEY_1,
    @"2" = glfw.KEY_2,
    @"3" = glfw.KEY_3,
    @"4" = glfw.KEY_4,
    @"5" = glfw.KEY_5,
    @"6" = glfw.KEY_6,
    @"7" = glfw.KEY_7,
    @"8" = glfw.KEY_8,
    @"9" = glfw.KEY_9,
    semicolon = glfw.KEY_SEMICOLON,
    equal = glfw.KEY_EQUAL,
    A = glfw.KEY_A,
    B = glfw.KEY_B,
    C = glfw.KEY_C,
    D = glfw.KEY_D,
    E = glfw.KEY_E,
    F = glfw.KEY_F,
    G = glfw.KEY_G,
    H = glfw.KEY_H,
    I = glfw.KEY_I,
    J = glfw.KEY_J,
    K = glfw.KEY_K,
    L = glfw.KEY_L,
    M = glfw.KEY_M,
    N = glfw.KEY_N,
    O = glfw.KEY_O,
    P = glfw.KEY_P,
    Q = glfw.KEY_Q,
    R = glfw.KEY_R,
    S = glfw.KEY_S,
    T = glfw.KEY_T,
    U = glfw.KEY_U,
    V = glfw.KEY_V,
    W = glfw.KEY_W,
    X = glfw.KEY_X,
    Y = glfw.KEY_Y,
    Z = glfw.KEY_Z,
    left_bracket = glfw.KEY_LEFT_BRACKET,
    backslash = glfw.KEY_BACKSLASH,
    right_bracket = glfw.KEY_RIGHT_BRACKET,
    grave_accent = glfw.KEY_GRAVE_ACCENT,
    world_1 = glfw.KEY_WORLD_1,
    world_2 = glfw.KEY_WORLD_2,
    escape = glfw.KEY_ESCAPE,
    enter = glfw.KEY_ENTER,
    tab = glfw.KEY_TAB,
    backspace = glfw.KEY_BACKSPACE,
    insert = glfw.KEY_INSERT,
    delete = glfw.KEY_DELETE,
    right = glfw.KEY_RIGHT,
    left = glfw.KEY_LEFT,
    down = glfw.KEY_DOWN,
    up = glfw.KEY_UP,
    page_up = glfw.KEY_PAGE_UP,
    page_down = glfw.KEY_PAGE_DOWN,
    home = glfw.KEY_HOME,
    end = glfw.KEY_END,
    caps_lock = glfw.KEY_CAPS_LOCK,
    scroll_lock = glfw.KEY_SCROLL_LOCK,
    num_lock = glfw.KEY_NUM_LOCK,
    print_screen = glfw.KEY_PRINT_SCREEN,
    pause = glfw.KEY_PAUSE,
    F1 = glfw.KEY_F1,
    F2 = glfw.KEY_F2,
    F3 = glfw.KEY_F3,
    F4 = glfw.KEY_F4,
    F5 = glfw.KEY_F5,
    F6 = glfw.KEY_F6,
    F7 = glfw.KEY_F7,
    F8 = glfw.KEY_F8,
    F9 = glfw.KEY_F9,
    F10 = glfw.KEY_F10,
    F11 = glfw.KEY_F11,
    F12 = glfw.KEY_F12,
    F13 = glfw.KEY_F13,
    F14 = glfw.KEY_F14,
    F15 = glfw.KEY_F15,
    F16 = glfw.KEY_F16,
    F17 = glfw.KEY_F17,
    F18 = glfw.KEY_F18,
    F19 = glfw.KEY_F19,
    F20 = glfw.KEY_F20,
    F21 = glfw.KEY_F21,
    F22 = glfw.KEY_F22,
    F23 = glfw.KEY_F23,
    F24 = glfw.KEY_F24,
    F25 = glfw.KEY_F25,
    KP_0 = glfw.KEY_KP_0,
    KP_1 = glfw.KEY_KP_1,
    KP_2 = glfw.KEY_KP_2,
    KP_3 = glfw.KEY_KP_3,
    KP_4 = glfw.KEY_KP_4,
    KP_5 = glfw.KEY_KP_5,
    KP_6 = glfw.KEY_KP_6,
    KP_7 = glfw.KEY_KP_7,
    KP_8 = glfw.KEY_KP_8,
    KP_9 = glfw.KEY_KP_9,
    KP_decimal = glfw.KEY_KP_DECIMAL,
    KP_divide = glfw.KEY_KP_DIVIDE,
    KP_multiply = glfw.KEY_KP_MULTIPLY,
    KP_subtract = glfw.KEY_KP_SUBTRACT,
    KP_add = glfw.KEY_KP_ADD,
    KP_enter = glfw.KEY_KP_ENTER,
    KP_equal = glfw.KEY_KP_EQUAL,
    left_shift = glfw.KEY_LEFT_SHIFT,
    left_control = glfw.KEY_LEFT_CONTROL,
    left_alt = glfw.KEY_LEFT_ALT,
    left_super = glfw.KEY_LEFT_SUPER,
    right_shift = glfw.KEY_RIGHT_SHIFT,
    right_control = glfw.KEY_RIGHT_CONTROL,
    right_alt = glfw.KEY_RIGHT_ALT,
    right_super = glfw.KEY_RIGHT_SUPER,
    menu = glfw.KEY_MENU,
    // last = glfw.KEY_LAST,
};

pub const Modify = packed struct {
    shift: bool,
    control: bool,
    alt: bool,
    super: bool,
    caps_lock: bool,
    num_lock: bool,
};

pub const Gamepad = struct {
    const State = struct {
        buttons: [15]input.State,
        axes: [6]f32,
    };

    pub const Axis = enum(c_int) {
        left_x = glfw.GAMEPAD_AXIS_LEFT_X,
        left_y = glfw.GAMEPAD_AXIS_LEFT_Y,
        right_x = glfw.GAMEPAD_AXIS_RIGHT_X,
        right_y = glfw.GAMEPAD_AXIS_RIGHT_Y,
        left_trigger = glfw.GAMEPAD_AXIS_LEFT_TRIGGER,
        right_trigger = glfw.GAMEPAD_AXIS_RIGHT_TRIGGER,
        // last = glfw.GAMEPAD_AXIS_LAST,
    };

    pub const Button = enum(c_int) {
        A = glfw.GAMEPAD_BUTTON_A,
        B = glfw.GAMEPAD_BUTTON_B,
        X = glfw.GAMEPAD_BUTTON_X,
        Y = glfw.GAMEPAD_BUTTON_Y,
        LEFT_BUMPER = glfw.GAMEPAD_BUTTON_LEFT_BUMPER,
        RIGHT_BUMPER = glfw.GAMEPAD_BUTTON_RIGHT_BUMPER,
        BACK = glfw.GAMEPAD_BUTTON_BACK,
        START = glfw.GAMEPAD_BUTTON_START,
        GUIDE = glfw.GAMEPAD_BUTTON_GUIDE,
        LEFT_THUMB = glfw.GAMEPAD_BUTTON_LEFT_THUMB,
        RIGHT_THUMB = glfw.GAMEPAD_BUTTON_RIGHT_THUMB,
        DPAD_UP = glfw.GAMEPAD_BUTTON_DPAD_UP,
        DPAD_RIGHT = glfw.GAMEPAD_BUTTON_DPAD_RIGHT,
        DPAD_DOWN = glfw.GAMEPAD_BUTTON_DPAD_DOWN,
        DPAD_LEFT = glfw.GAMEPAD_BUTTON_DPAD_LEFT,
        // LAST = glfw.GAMEPAD_BUTTON_LAST,
        // CROSS = glfw.GAMEPAD_BUTTON_CROSS,
        // CIRCLE = glfw.GAMEPAD_BUTTON_CIRCLE,
        // SQUARE = glfw.GAMEPAD_BUTTON_SQUARE,
        // TRIANGLE = glfw.GAMEPAD_BUTTON_TRIANGLE,
    };

    pub const Joystick = enum(c_int) {
        @"1" = glfw.JOYSTICK_1,
        @"2" = glfw.JOYSTICK_2,
        @"3" = glfw.JOYSTICK_3,
        @"4" = glfw.JOYSTICK_4,
        @"5" = glfw.JOYSTICK_5,
        @"6" = glfw.JOYSTICK_6,
        @"7" = glfw.JOYSTICK_7,
        @"8" = glfw.JOYSTICK_8,
        @"9" = glfw.JOYSTICK_9,
        @"10" = glfw.JOYSTICK_10,
        @"11" = glfw.JOYSTICK_11,
        @"12" = glfw.JOYSTICK_12,
        @"13" = glfw.JOYSTICK_13,
        @"14" = glfw.JOYSTICK_14,
        @"15" = glfw.JOYSTICK_15,
        @"16" = glfw.JOYSTICK_16,
        // @"LAST" = glfw.JOYSTICK_LAST,

        const Event = enum(c_int) {
            connect = glfw.CONNECTED,
            disconnect = glfw.DISCONNECTED,
        };

        const Callback = *const fn (Joystick, Event) void;

        var callback_func: ?Callback = null;
        fn callback(jid: c_int, event: c_int) callconv(.c) void {
            if (callback_func) |func| {
                func(@enumFromInt(jid), @enumFromInt(event));
            }
        }

        pub fn enable_callback() void {
            _ = glfw.setJoystickCallback(&callback);
        }

        pub fn setCallback(func: Callback) ?Callback {
            const ret = callback_func;
            callback_func = func;
            return ret;
        }

        pub fn getCallback() ?Callback {
            return callback_func;
        }

        pub fn present(self: Joystick) bool {
            return glfw.joystickPresent(@intFromEnum(self)) == glfw.TRUE;
        }

        pub fn getAxes(self: Joystick) []const f32 {
            var count: c_int = undefined;
            const axes = glfw.getJoystickAxes(@intFromEnum(self), &count);
            if (axes == null) {
                @branchHint(.cold);
                glfw.check() catch unreachable;
                return &.{};
            }
            return axes[0..count];
        }

        /// **The caller owns the returned memory.**
        pub fn getButton(self: Joystick, allocator: Allocator) ?[]const input.State {
            var count: c_int = undefined;
            const states = glfw.getJoystickButtons(@intFromEnum(self), &count);
            if (states == null) {
                @branchHint(.cold);
                glfw.check() catch unreachable;
                return null;
            }
            const arr = try std.ArrayList(input.State).initCapacity(allocator, @intCast(count));
            for (0..count) |i| {
                arr.append(allocator, @enumFromInt(states[i]));
            }
            return arr.toOwnedSlice(allocator);
        }

        /// **The caller owns the returned memory.**
        pub fn getHats(self: Joystick, allocator: Allocator) ?[]const Hat {
            var count: c_int = undefined;
            const hats = glfw.getJoystickHats(@intFromEnum(self), &count);
            if (hats == null) {
                @branchHint(.cold);
                glfw.check() catch unreachable;
                return null;
            }
            const arr = try std.ArrayList(input.State).initCapacity(allocator, @intCast(count));
            for (0..count) |i| {
                arr.append(allocator, @bitCast(@as(u4, @intCast(hats[i]))));
            }
            return arr.toOwnedSlice(allocator);
        }

        pub fn getName(self: Joystick) ?[]const u8 {
            const name = glfw.getJoystickName(@intFromEnum(self));
            if (name == null) {
                @branchHint(.cold);
                glfw.check() catch unreachable;
                return null;
            }
            return name[0..std.mem.len(name)];
        }

        pub fn getGUID(self: Joystick) ?[]const u8 {
            const guid = glfw.getJoystickGUID(@intFromEnum(self));
            if (guid == null) {
                @branchHint(.cold);
                glfw.check() catch unreachable;
                return null;
            }
            return guid[0..std.mem.len(guid)];
        }

        pub fn setUserPointer(self: Joystick, ptr: *anyopaque) void {
            glfw.setJoystickUserPointer(@intFromEnum(self), ptr);
        }

        pub fn getUserPointer(self: Joystick, comptime T: type) *T {
            return @ptrCast(glfw.getJoystickUserPointer(@intFromEnum(self)));
        }

        pub fn isGamepad(self: Joystick) bool {
            return glfw.joystickIsGamepad(@intFromEnum(self)) == glfw.TRUE;
        }

        pub fn updateGamepadMappings(string: []const u8) error{InvalidValue}!void {
            const ret = glfw.updateGamepadMappings(string);
            if (ret == glfw.FALSE) {
                glfw.check() catch |err| switch (err) {
                    error.InvalidValue,
                    => return @errorCast(err),
                    else => unreachable,
                };
                try glfw.check();
            }
        }

        pub fn getGamepadName(self: Joystick) ?[]const u8 {
            const name = glfw.getGamepadName(@intFromEnum(self));
            if (name == null) {
                @branchHint(.cold);
                glfw.check() catch unreachable;
                return null;
            }
            return name[0..std.mem.len(name)];
        }

        pub fn getGamepadState(self: Joystick) ?Gamepad.State {
            var glfw_state: glfw.GamepadState = undefined;
            const ret = glfw.getGamepadState(@intFromEnum(self), &glfw_state);
            if (ret == glfw.FALSE) {
                @branchHint(.cold);
                glfw.check() catch unreachable;
                return null;
            }
            var btns: [15]input.State = undefined;
            inline for (0..15) |i| {
                btns[i] = @enumFromInt(glfw_state[i]);
            }
            return .{
                .buttons = btns,
                .axes = glfw_state.axes,
            };
        }
    };
};

pub const Hat = packed struct {
    up: bool,
    right: bool,
    down: bool,
    left: bool,
};

pub const MouseButton = enum(c_int) {
    // @"1" = glfw.MOUSE_BUTTON_1,
    // @"2" = glfw.MOUSE_BUTTON_2,
    // @"3" = glfw.MOUSE_BUTTON_3,
    @"4" = glfw.MOUSE_BUTTON_4,
    @"5" = glfw.MOUSE_BUTTON_5,
    @"6" = glfw.MOUSE_BUTTON_6,
    @"7" = glfw.MOUSE_BUTTON_7,
    @"8" = glfw.MOUSE_BUTTON_8,
    // LAST = glfw.MOUSE_BUTTON_LAST,
    LEFT = glfw.MOUSE_BUTTON_LEFT,
    RIGHT = glfw.MOUSE_BUTTON_RIGHT,
    MIDDLE = glfw.MOUSE_BUTTON_MIDDLE,
};

pub const ModeType = enum(c_int) {
    cursor = glfw.CURSOR,
    sticky_keys = glfw.STICKY_KEYS,
    sticky_mouse_buttons = glfw.STICKY_MOUSE_BUTTONS,
    lock_key_mods = glfw.LOCK_KEY_MODS,
    raw_mouse_motion = glfw.RAW_MOUSE_MOTION,
};

pub const Cursor = enum(c_int) {
    normal = glfw.CURSOR_NORMAL,
    hidden = glfw.CURSOR_HIDDEN,
    disabled = glfw.CURSOR_DISABLED,
    captured = glfw.CURSOR_CAPTURED,
};

pub const Mode = union(ModeType) {
    cursor: Cursor,
    sticky_keys: bool,
    sticky_mouse_buttons: bool,
    lock_key_mods: bool,
    raw_mouse_motion: bool,
};

pub fn rawMouseMovtionSupported() bool {
    return glfw.rawMouseMotionSupported() == glfw.TRUE;
}

pub const Key2 = union(enum) {
    key: Key,
    scancode: u32,
};

pub fn getKeyName(key: Key2) error{InvalidValue}!?[]const u8 {
    const name = switch (key) {
        .key => |k| glfw.getKeyName(@intFromEnum(k), 0),
        .scancode => |sc| glfw.getKeyName(glfw.KEY_UNKNOWN, @intCast(sc)),
    };
    if (name == null) {
        @branchHint(.cold);
        glfw.check() catch |err| switch (err) {
            error.InvalidValue => return @errorCast(err),
            else => unreachable,
        };
        return null;
    }
    return name[0..std.mem.len(name)];
}

pub fn getKeyScancode(key: Key) ?u32 {
    const scancode = glfw.getKeyScancode(@intFromEnum(key));
    if (scancode == -1) {
        @branchHint(.cold);
        glfw.check() catch unreachable;
        return null;
    }
    return scancode;
}

pub const Action = enum(c_int) {
    press = glfw.PRESS,
    release = glfw.RELEASE,
    repeat = glfw.REPEAT,
};


pub const State = enum(c_int) {
    press = glfw.PRESS,
    release = glfw.RELEASE,
};