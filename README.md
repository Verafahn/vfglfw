# vfglfw

GLFW bindings for Zig with an idiomatic wrapper on top. The wrapper covers the default GLFW API — windows, monitors, cursors, images, input, clipboard, timing, and platform queries — and adds:

- typed hints and enums instead of integer constants
- tagged-union events delivered through one `Window.setHandle` callback
- optional `std.mem.Allocator` integration for GLFW's internal allocations
- Zig error sets instead of return codes

## Requirements

- Zig 0.17.0 or newer.
- A platform supported by GLFW.

## Installation

```sh
zig fetch --save git+https://github.com/Verafahn/vfglfw
```

Add the module to `build.zig`:

```zig
const vfglfw = b.dependency("vfglfw", .{
    .target = target,
    .optimize = optimize,
    // Optional, both default to false:
    .link_glfw = true, // Build and link GLFW from the pinned glfw.zig dependency.
    .use_gl = true,    // Expose `glfw.gl`, a GLAD-generated OpenGL 4.6 loader.
});

const exe = b.addExecutable(.{
    .name = "my-app",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "vfglfw", .module = vfglfw.module("vfglfw") },
        },
    }),
});
b.installArtifact(exe);
```

Then import it with `const glfw = @import("vfglfw");`.

Without `link_glfw`, link an ABI-compatible GLFW build yourself. The bindings are generated from the `glfw3.h` shipped with the pinned `glfw.zig` release.

## Quick start

```zig
const std = @import("std");
const glfw = @import("vfglfw");
const Event = glfw.Handle.Event;

const App = struct {
    event_count: usize = 0,

    fn handle(self: *App) glfw.Handle {
        return .{
            .vptr = self,
            .vtable = .{ .handle = &onEvent },
        };
    }

    fn onEvent(vptr: *anyopaque, event: Event) void {
        const self: *App = @ptrCast(@alignCast(vptr));
        self.event_count += 1;

        switch (event) {
            .cursor_pos => |pos| {
                std.debug.print("cursor: {d}, {d}\n", .{ pos.x, pos.y });
            },
            .key => |key| if (key.action == .press) {
                std.debug.print("key: {s}\n", .{@tagName(key.key)});
            },
            .mouse_button => |button| if (button.action == .press) {
                std.debug.print("mouse button: {s}\n", .{@tagName(button.button)});
            },
            else => {},
        }
    }
};

pub fn main(init: std.process.Init) !void {
    try glfw.init(init.gpa, .{});
    defer glfw.deinit();

    var window = try glfw.Window.create(1280, 720, "vfglfw demo", .{
        .resizable = false,
    });
    defer window.destroy();

    var app: App = .{};
    window.setHandle(app.handle(), .{
        .cursor_pos = true,
        .key = true,
        .mouse_button = true,
    });

    while (!window.shouldClose()) {
        window.swapBuffer();
        glfw.event.poll();
    }
}
```

`glfw.event.poll()` processes pending events without blocking; use `glfw.event.wait()` or `glfw.event.waitTimeout(seconds)` to block.

## OpenGL

With `use_gl` enabled, load the GL functions after making the context current:

```zig
const gl = glfw.gl;

// Inside main, after `glfw.init`:
var window = try glfw.Window.create(1280, 720, "OpenGL", .{
    .context_version_major = 4,
    .context_version_minor = 6,
    .opengl_profile = .core,
});
defer window.destroy();
window.makeContextCurrent();

if (gl.loadGLLoader(@ptrCast(&glfw.getProcAddress)) == 0)
    return error.OpenGLLoadFailed;
```

`glfw.getProcAddress` is also available for use with other loaders.

## Examples

```sh
zig build exp_window      # Window and input events
zig build exp_background  # OpenGL clear
zig build exp_triangle    # OpenGL 4.6 with SPIR-V shaders
```

Arguments after `--` are forwarded to the example program. The OpenGL examples enable `use_gl` and `link_glfw` automatically.

## License

This repository is licensed under the MIT License.
