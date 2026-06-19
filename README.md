# ziglfw

`ziglfw` is a Zig-style wrapper for GLFW that provides an object-oriented API while allowing you to replace GLFW's allocator with Zig's allocator, as shown below.

```zig
const std = @import("std");
const glfw = @import("ziglfw");

pub fn main(init: std.process.Init) !void {
    try glfw.init(init.gpa, .{});
    defer glfw.deinit();

    var window = try glfw.Window.create(1600, 900, "Demo", .{});
    defer window.destroy();

    window.makeContextCurrent();

    while (!window.shouldClose()) {
        window.swapBuffer();
        glfw.event.poll();
    }
}
```

## Usage

Add `ziglfw` to your project with:

```
zig fetch git+https://github.com/Verafahn/ziglfw#master --save
```

Then add the following to your `build.zig`:

```zig
const zglfw = b.dependency("ziglfw", .{
    .target = target,
    .optimize = optimize,
});
...
    .imports = &.{
        .{ .name = "ziglfw", .module = zglfw.module("ziglfw") },
    },
...
```

Now you can import it like any other dependency:

```zig
const glfw = @import("ziglfw");
```

## Notes

`ziglfw` is purely a wrapper around the GLFW interface. It does not bundle any GLFW library files; you are free to link GLFW in whichever way you prefer.