const std = @import("std");
const glfw = @import("glfw3c");
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len != 2) {
        std.log.err("Args error.", .{});
    }

    const output_file_path = args[1];
    
    var file = try std.Io.Dir.cwd().createFile(io, output_file_path, .{});
    defer file.close(io);

    var buffer: [64]u8 = undefined;
    var writer = file.writer(io, &buffer);

    try writer.interface.writeAll(
        \\//! This file generate by bin/glfw_gen.zig
        \\
        \\const glfw = @import("glfw3c");
        \\
        \\pub const Error = error{
        \\    NoCurrentContext,
        \\    InvalidValue,
        \\    OutOfMemory,
        \\    ApiUnavailable,
        \\    VersionUnavailable,
        \\    FormatUnavailable,
        \\    NoWindowContext,
        \\    CursorUnavailable,
        \\    FeatureUnavailable,
        \\    FeatureUnimplemented,
        \\    PlatformUnavailable,
        \\};
        \\
        \\pub fn check() Error!void {
        \\    switch (getError(null)) {
        \\        NO_ERROR => return,
        \\        NOT_INITIALIZED => @panic("GLFW Not Initialized."), // Call glfw.init()
        \\        NO_CURRENT_CONTEXT => return error.NoCurrentContext,
        \\        INVALID_ENUM => @panic("Implementation error."),  // Library implementation error, please provide feedback to issue
        \\        INVALID_VALUE => return error.InvalidValue,
        \\        OUT_OF_MEMORY => return error.OutOfMemory,
        \\        API_UNAVAILABLE => return error.ApiUnavailable,
        \\        VERSION_UNAVAILABLE => return error.VersionUnavailable,
        \\        PLATFORM_ERROR => @panic("Platform-specific error"),
        \\        FORMAT_UNAVAILABLE => return error.FormatUnavailable,
        \\        NO_WINDOW_CONTEXT => return error.NoWindowContext,
        \\        CURSOR_UNAVAILABLE => return error.CursorUnavailable,
        \\        FEATURE_UNAVAILABLE => return error.FeatureUnavailable,
        \\        FEATURE_UNIMPLEMENTED => return error.FeatureUnimplemented,
        \\        PLATFORM_UNAVAILABLE => return error.PlatformUnavailable,
        \\        else => unreachable,
        \\    }
        \\}
        \\
        \\pub const GLProc = glfw.GLFWglproc;
        \\pub const VKProc = glfw.GLFWvkproc;
        \\pub const Monitor = glfw.GLFWmonitor;
        \\pub const Window = glfw.GLFWwindow;
        \\pub const Cursor = glfw.GLFWcursor;
        \\pub const AllocateFun = glfw.GLFWallocatefun;
        \\pub const ReAllocateFun = glfw.GLFWreallocatefun;
        \\pub const DeAllocateFun = glfw.GLFWdeallocatefun;
        \\pub const ErrorFun = glfw.GLFWerrorfun;
        \\pub const WindowPosFun = glfw.GLFWwindowposfun;
        \\pub const WindowSizeFun = glfw.GLFWwindowsizefun;
        \\pub const WindowCloseFun = glfw.GLFWwindowclosefun;
        \\pub const WindowRefreshFun = glfw.GLFWwindowrefreshfun;
        \\pub const WindowFocusFun = glfw.GLFWwindowfocusfun;
        \\pub const WindowIconifyFun = glfw.GLFWwindowiconifyfun;
        \\pub const WindowMaximizeFun = glfw.GLFWwindowmaximizefun;
        \\pub const FrameBufferSizeFun = glfw.GLFWframebuffersizefun;
        \\pub const WindowContentScaleFun = glfw.GLFWwindowcontentscalefun;
        \\pub const MouseButtonFun = glfw.GLFWmousebuttonfun;
        \\pub const CursorPosFun = glfw.GLFWcursorposfun;
        \\pub const CursorEnterFun = glfw.GLFWcursorenterfun;
        \\pub const ScrollFun = glfw.GLFWscrollfun;
        \\pub const KeyFun = glfw.GLFWkeyfun;
        \\pub const CharFun = glfw.GLFWcharfun;
        \\pub const CharModsFun = glfw.GLFWcharmodsfun;
        \\pub const DropFun = glfw.GLFWdropfun;
        \\pub const MonitorFun = glfw.GLFWmonitorfun;
        \\pub const JoystickFun = glfw.GLFWjoystickfun;
        \\pub const VidMode = glfw.GLFWvidmode;
        \\pub const GammarAmp = glfw.GLFWgammaramp;
        \\pub const Image = glfw.GLFWimage;
        \\pub const GamepadState = glfw.GLFWgamepadstate;
        \\pub const Allocator = glfw.GLFWallocator;
        \\
        \\
    );

    const decls = @typeInfo(glfw).@"struct".decls;
    for (decls) |decl| {
        if (std.mem.startsWith(u8, decl.name, "glfw") and decl.name.len > 4) {
            const subname = decl.name[4..];
            try writer.interface.print(
                "pub const {c}{s}: *const @TypeOf(glfw.{s}) = &glfw.{s};\n",
                .{
                    std.ascii.toLower(subname[0]),
                    subname[1..],
                    decl.name,
                    decl.name,
                },
            );
        } else if (std.mem.startsWith(u8, decl.name, "GLFW_") and decl.name.len > 5) {
            const subname = decl.name[5..];
            try writer.interface.print(
                "pub const {s} = @as(c_int, glfw.{s});\n",
                .{
                    subname,
                    decl.name,
                },
            );
        }
    }

    try writer.interface.flush();
}
