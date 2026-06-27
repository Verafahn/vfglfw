const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vfglfw = b.dependency("vfglfw", .{
        .target = target,
        .optimize = optimize,
    });
    const zgl = b.dependency("zgl", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "ziglfw", .module = vfglfw.module("vfglfw") },
            .{ .name = "zgl", .module = zgl.module("zgl") },
        },
    });
    mod.addLibraryPath(b.path("lib/"));
    mod.linkSystemLibrary("glfw3", .{});

    const exe = b.addExecutable(.{
        .name = "demo",
        .root_module = mod,
    });

    b.installArtifact(exe);
    b.installBinFile("lib/glfw3.dll", "glfw3.dll");

    const run_step = b.step("run", "Run demo.");
    const run = b.addRunArtifact(exe);
    run_step.dependOn(&run.step);
    run.step.dependOn(b.getInstallStep());
}
