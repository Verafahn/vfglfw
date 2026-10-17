const std = @import("std");
const Translator = @import("translate_c").Translator;
const glad = @import("glad");

var target: std.Build.ResolvedTarget = undefined;
var optimize: std.builtin.Optimize = undefined;
var glad_mod: *std.Build.Module = undefined;
var vfglfw: *std.Build.Dependency = undefined;

pub fn build(b: *std.Build) !void {
    target = b.standardTargetOptions(.{});
    optimize = b.standardOptimizeOption(.{});
    glad_mod = glad.gladModule(
        b,
        b.dependency("glad", .{}),
        target,
        optimize,
    );
    vfglfw = b.dependency("vfglfw", .{
        .target = target,
        .optimize = optimize,
        .link_glfw = true,
    });
    const opengl_target = b.resolveTargetQuery(.{
        .cpu_arch = .spirv32,
        .os_tag = .opengl,
        .ofmt = .spirv,
    });

    const vertex = b.addObject(.{
        .name = "vertex",
        .root_module = b.createModule(.{
            .root_source_file = b.path("shaders/vertex.zig"),
            .target = opengl_target,
            .optimize = .fast,
        }),
        .use_llvm = false,
        .use_lld = false,
    });
    const vertex_path = vertex.getEmittedBin();
    const fragment = b.addObject(.{
        .name = "fragment",
        .root_module = b.createModule(.{
            .root_source_file = b.path("shaders/fragment.zig"),
            .target = opengl_target,
            .optimize = .fast,
        }),
        .use_llvm = false,
        .use_lld = false,
    });
    const fragment_path = fragment.getEmittedBin();

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "vfglfw", .module = vfglfw.module("vfglfw") },
            .{ .name = "glad", .module = glad_mod },
        },
    });
    mod.addAnonymousImport("vertex", .{
        .root_source_file = vertex_path,
    });
    mod.addAnonymousImport("fragment", .{
        .root_source_file = fragment_path,
    });

    const exe = b.addExecutable(.{
        .name = "triangle",
        .root_module = mod,
    });
    b.installArtifact(exe);
    const run = b.addRunArtifact(exe);
    run.addPassthruArgs();
    run.step.dependOn(b.getInstallStep());
    const step = b.step("run", "");
    step.dependOn(&run.step);
}
