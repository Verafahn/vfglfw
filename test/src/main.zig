const std = @import("std");
const glfw = @import("vfglfw");
const Event = glfw.Handle.Event;

pub fn handle(_: *anyopaque, event: Event) void {
    switch (event) {
        .cursor_pos => |info| {
            const x, const y = .{ info.x, info.y };
            std.debug.print("Pos({}, {})\n", .{ x, y });
        },
        else => {
            std.debug.print("{any}\n", .{event});
        },
    }
}

pub fn main(init: std.process.Init) !void {
    try glfw.init(init.gpa, .{});
    defer glfw.deinit();

    var window = try glfw.Window.create(1600, 900, "Demo", .{});
    defer window.destroy();
    window.setHandle(.{
        .vptr = undefined,
        .vtable = .{ .handle = &handle },
    }, .{
        .cursor_pos = true,
        .pos = true,
    });

    while (!window.shouldClose()) {
        window.swapBuffer();
        glfw.event.poll();
    }
}
