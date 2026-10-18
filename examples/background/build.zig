const std = @import("std");
const Translator = @import("translate_c").Translator;

var target: std.Build.ResolvedTarget = undefined;
var optimize: std.builtin.Optimize = undefined;
var glad_mod: *std.Build.Module = undefined;
var vfglfw: *std.Build.Dependency = undefined;

pub fn build(b: *std.Build) !void {
    target = b.standardTargetOptions(.{});
    optimize = b.standardOptimizeOption(.{});
    vfglfw = b.dependency("vfglfw", .{
        .target = target,
        .optimize = optimize,
        .link_glfw = true,
        .use_gl = true,
    });

    const exe = b.addExecutable(.{
        .name = "triangle",
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
    const run = b.addRunArtifact(exe);
    run.addPassthruArgs();
    run.step.dependOn(b.getInstallStep());
    const step = b.step("run", "");
    step.dependOn(&run.step);
}
