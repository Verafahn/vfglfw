const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // GLFW3 Header file import.
    const glfw3 = b.addTranslateC(.{
        .root_source_file = b.path("include/c.h"),
        .optimize = optimize,
        .target = target,
    });
    // Generate rename bind.
    const gen = b.addExecutable(.{
        .name = "glfw_gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("bin/glfw_gen.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "glfw3.c", .module = glfw3.createModule() },
            },
        }),
    });
    const gen_step = b.addRunArtifact(gen);
    const output = gen_step.addOutputFileArg("glfw3");

    // Export module 'zglfw'.
    const zglfw = b.addModule("zglfw", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{
                .name = "glfw.zig",
                .module = b.createModule(.{
                    .root_source_file = output,
                    .target = target,
                    .optimize = optimize,
                    .imports = &.{
                        .{ .name = "glfw3.c", .module = glfw3.createModule() },
                    },
                }),
            },
        },
    });
    _ = zglfw;
}
