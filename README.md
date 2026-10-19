# vfglfw

[GLFW](https://www.glfw.org/) bindings for Zig with an idiomatic wrapper on top.

`vfglfw` exposes the default GLFW API through Zig types: enums instead of integer constants, optionals instead of sentinel values, tagged unions instead of `void` pointers, and error sets instead of return codes. It also lets you install a Zig allocator for GLFW's internal allocations and route window events through a single callback.

## Features

- **Covers the default GLFW API** — windows, monitors, cursors, images, input, clipboard, timing, and platform queries. Declarations guarded by optional feature macros are not included.
- **Allocator integration** — pass any `std.mem.Allocator` to `glfw.init`; GLFW's allocations will use it.
- **Typed hints** — optional fields in `glfw.Hint` and `glfw.Window.Hint`; unspecified hints keep GLFW's defaults.
- **Unified event handling** — `Window.setHandle` installs a vtable plus an `EventConfig`; events arrive as a `Handle.Event` tagged union.
- **Zig error sets** — GLFW error codes are mapped to Zig errors.
- **Optional OpenGL loader** — enable `use_gl` to get `glfw.gl`, a GLAD-generated OpenGL 4.6 loader.
- **Optional bundled GLFW** — enable `link_glfw` to build and link GLFW from the pinned `glfw.zig` dependency.

## Requirements

- Zig 0.17.0 or newer.
- A platform supported by GLFW. When `link_glfw` is enabled, GLFW's own build requirements apply.

## Installation

Add the dependency:

```sh
zig fetch --save git+https://github.com/Verafahn/vfglfw
```

This adds `vfglfw` to your `build.zig.zon`. Then wire the module and options into `build.zig`:

```zig
const vfglfw = b.dependency("vfglfw", .{
    .target = target,
    .optimize = optimize,
    // Optional: build and link GLFW from source via glfw.zig.
    .link_glfw = true,
    // Optional: expose `glfw.gl` (GLAD OpenGL loader).
    .use_gl = true,
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

Both options default to `false`.

| Option | Default | Effect |
| --- | --- | --- |
| `link_glfw` | `false` | Links the GLFW library provided by the `glfw.zig` dependency. Leave it off if your build already links GLFW. |
| `use_gl` | `false` | Adds `glfw.gl`, a GLAD-generated OpenGL 4.6 loader, importable as `const gl = glfw.gl;`. |

Then import the package like any other module:

```zig
const glfw = @import("vfglfw");
```

## Quick start

The example below assumes GLFW is linked, either by enabling `link_glfw` or by your own build setup.

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
    // Replace GLFW's default allocator with `init.gpa`.
    try glfw.init(init.gpa, .{});
    defer glfw.deinit();

    var window = try glfw.Window.create(1280, 720, "vfglfw demo", .{
        .resizable = false,
    });
    defer window.destroy();

    // Point `vptr` at application state, then subscribe to events.
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

`EventConfig` enables only the GLFW callbacks you subscribe to. `glfw.event.poll()` processes pending events without blocking; use `glfw.event.wait()` or `glfw.event.waitTimeout(seconds)` to block instead.

## OpenGL

With `use_gl` enabled, the GLAD loader is available as `glfw.gl`. Make the context current and load the function pointers after creating the window:

```zig
const gl = glfw.gl;

// ... inside main, after `glfw.init`:
var window = try glfw.Window.create(1280, 720, "OpenGL", .{
    .context_version_major = 4,
    .context_version_minor = 6,
    .opengl_profile = .core,
});
defer window.destroy();
window.makeContextCurrent();

if (gl.loadGLLoader(@ptrCast(&glfw.getProcAddress)) == 0)
    return error.OpenGLLoadFailed;

while (!window.shouldClose()) {
    gl.clearColor(0.1, 0.1, 0.1, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);

    window.swapBuffer();
    glfw.event.poll();
}
```

`glfw.getProcAddress` is also available when you prefer a different loader.

## API overview

| Import | Contents |
| --- | --- |
| `@import("vfglfw")` | `init` / `deinit`, event polling, clipboard and timing helpers, platform queries, initial hints, and shared types (`Pos`, `Size`, `Rectangle`, `Scale`). |
| `glfw.Window` | Window creation, hints, attributes, input modes, icon, fullscreen mode, cursor position, and event handling. |
| `glfw.Monitor` | Monitor enumeration, work area, physical size, content scale, video modes, gamma, and hotplug events. |
| `glfw.Cursor` / `glfw.Image` | Standard and custom cursors. |
| `glfw.input` | `Key`, `MouseButton`, `Action`, `State`, `Modify`, plus joystick and gamepad state. |
| `glfw.Handle` | `Event`, `EventConfig`, and the callback vtable used by `Window.setHandle`. |
| `glfw.gl` | Optional GLAD OpenGL loader, available when `use_gl` is enabled. |

## Examples

The repository contains runnable examples:

```sh
zig build exp_window      # Open a window and print input events
zig build exp_background  # Clear the framebuffer with OpenGL
zig build exp_triangle    # Draw a triangle with OpenGL 4.6 and SPIR-V shaders
```

Arguments after `--` are forwarded to the example program. The OpenGL examples enable `use_gl` and `link_glfw` automatically.

## Providing GLFW

By default, `vfglfw` translates `glfw3.h` from the pinned `glfw.zig` dependency at build time but does not link a GLFW implementation. You can:

- set `link_glfw = true` to build and link GLFW from that dependency, or
- link your own GLFW build, for example one built from source or provided by the system.

When linking your own copy, make sure it is ABI-compatible with the header shipped by the pinned `glfw.zig` release.

## License

This repository is licensed under the MIT License.
