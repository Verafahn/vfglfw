# vfglfw

A Zig-idiomatic wrapper around the GLFW library that provides a significantly more ergonomic API than raw C header bindings.

## About

`vfglfw` exposes all **120 default GLFW APIs** out-of-the-box—without requiring any feature macros. It enables you to substitute GLFW's internal memory allocator with your own custom implementation and streamlines window event handling through an intuitive, type-safe interface.

## Key Features

- **Full API Coverage**: Wraps all 120 standard GLFW functions (excluding feature-macro guarded ones) with zero runtime overhead.
- **Custom Allocator Support**: Seamlessly replace GLFW's default memory allocator with your Zig allocator (e.g., `gpa`) for unified memory management.
- **Ergonomic Event Handling**: Handle window events via a clean, switch-based dispatch pattern instead of cumbersome C function pointers.
- **Batteries-Not-Included GLFW**: Decouples the GLFW implementation, giving you total freedom to choose your preferred binary or source distribution.

## Installation

Add `vfglfw` to your `build.zig.zon` dependencies:

```bash
zig fetch git+https://github.com/Verafahn/vfglfw --save
```

Then, register the module in your `build.zig` file:

```zig
const vfglfw = b.dependency("vfglfw", .{
    .target = target,
    .optimize = optimize,
});

// Add this to your executable or library's imports:
    .imports = &.{
        .{ .name = "vfglfw", .module = vfglfw.module("vfglfw") },
    },
```

Now you can import and use it just like the standard library:

```zig
const glfw = @import("vfglfw");
```

## Quick Start

The following example demonstrates how to set up a window, override the default allocator, and handle cursor movement events:

```zig
const std = @import("std");
const glfw = @import("vfglfw");
const Event = glfw.Handle.Event;

// Customize window event handling functions.
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
    // Replace GLFW default allocator with `init.gpa`.
    try glfw.init(init.gpa, .{});
    defer glfw.deinit();

    var window = try glfw.Window.create(1600, 900, "Demo", .{});
    defer window.destroy();

    // Set `Handle` instance and the types of events to be handled.
    window.setHandle(.{
        .vptr = undefined,
        .vtable = .{ .handle = &handle },
    }, .{
        .cursor_pos = true,
        .pos = true,
    });

    // Event loop.
    while (!window.shouldClose()) {
        window.swapBuffer();
        glfw.event.poll();
    }
}
```

## GLFW Dependency Notes

> **Note:** `vfglfw` does **not** bundle any GLFW implementation by default.  
> You are free to link it against any source-built GLFW, official pre-compiled binaries, or even alternative Zig-friendly distributions like [glfw.zig](https://github.com/tiawl/glfw.zig). Ensure the GLFW library is available in your system or project linker path.

## License

This repository is distributed under the **MIT License**. See the `LICENSE` file for more details.