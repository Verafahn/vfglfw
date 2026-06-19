const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // GLFW3 Header file import.
    const glfw3c = b.addTranslateC(.{
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

    // Export module 'zglfw'.
    const zglfw = b.addModule("zglfw", .{
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

    // Used to reference symbols to check compilation..
    const lib = b.addLibrary(.{
        .name = "glfw",
        .root_module = zglfw,
    });

    b.installArtifact(lib);
}
