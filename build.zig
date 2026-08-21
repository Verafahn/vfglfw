const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // GLFW3 Header file import.
    const glfw3c = b.addTranslateC(.{
        .root_source_file = b.path("src/include/c.h"),
        .optimize = optimize,
        .target = target,
    });
    // Generate rename bind.
    const gen = b.addExecutable(.{
        .name = "glfw_gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/bin/glfw_gen.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "glfw3c", .module = glfw3c.createModule() },
            },
        }),
    });
    const gen_step = b.addRunArtifact(gen);
    const output = gen_step.addOutputFileArg("glfw3.zig");
    const glfw3 = b.createModule(.{
        .root_source_file = output,
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "glfw3c", .module = glfw3c.createModule() },
        },
    });

    // Export module 'vfglfw'.
    const vfglfw = b.addModule("vfglfw", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{
                .name = "glfw3",
                .module = glfw3,
            },
        },
    });

    // use `-Duse_glfw_zig` to enable.
    if (b.option(
        bool,
        "use_glfw_zig",
        "If this parameter is specified, it will link to glfw.zig(https://github.com/tiawl/glfw.zig).",
    ) orelse false) {
        const glfw_zig = b.dependency("glfw_zig", .{});
        vfglfw.linkLibrary(glfw_zig.artifact("glfw"));
    }

    {
        const test_window = b.addExecutable(.{
            .name = "test_window",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .root_source_file = b.path("test/window/main.zig"),
                .imports = &.{
                    .{ .name = "vfglfw", .module = vfglfw },
                },
            }),
        });
        const run_test_window = b.addRunArtifact(test_window);
        const step_test_window = b.step("test_window", "Run test 'window'.");
        step_test_window.dependOn(&run_test_window.step);
    }
}
