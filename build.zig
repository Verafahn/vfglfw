const std = @import("std");
const Translator = @import("translate_c").Translator;

var target: std.Build.ResolvedTarget = undefined;
var optimize: std.builtin.Optimize = undefined;
var glfw_zig: *std.Build.Dependency = undefined;
var translate_c: *std.Build.Dependency = undefined;
var glfw3_h_mod: *std.Build.Module = undefined;
var glfw3_mod: *std.Build.Module = undefined;
var vfglfw_mod: *std.Build.Module = undefined;

pub fn build(b: *std.Build) !void {
    const io = b.graph.io;

    target = b.standardTargetOptions(.{});
    optimize = b.standardOptimizeOption(.{});
    glfw_zig = b.dependency("glfw_zig", .{
        .target = target,
        .optimize = optimize,
    });
    translate_c = b.dependency("translate_c", .{});

    const glfw3_h: Translator = .init(translate_c, .{
        .c_source_file = glfw_zig.path("glfw/include/GLFW/glfw3.h"),
        .target = target,
        .optimize = optimize,
    });
    glfw3_h_mod = glfw3_h.mod;

    glfw3_mod = createGlfw3Mod(b);

    if (b.option(bool, "link_glfw", "") orelse false) {
        glfw3_mod.linkLibrary(glfw_zig.artifact("glfw"));
    }

    vfglfw_mod = b.addModule("vfglfw", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "glfw3", .module = glfw3_mod },
        },
    });

    try build_all_examples(b, io);
}

fn createGlfw3Mod(b: *std.Build) *std.Build.Module {
    const glfw_gen = b.addExecutable(.{
        .name = "glfw_gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/gen/glfw_gen.zig"),
            .target = b.graph.host,
            .optimize = .safe,
            .imports = &.{
                .{ .name = "glfw3.h", .module = glfw3_h_mod },
            },
        }),
    });
    const glfw_gen_run = b.addRunArtifact(glfw_gen);
    const path = glfw_gen_run.addOutputFileArg("glfw3.zig");
    return b.createModule(.{
        .root_source_file = path,
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "glfw3.h", .module = glfw3_h_mod },
        },
    });
}

fn existFile(io: std.Io, dir: std.Io.Dir, file: []const u8) !bool {
    const stat = dir.statFile(io, file, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return err,
    };
    return stat.kind == .file;
}

fn build_file_examples(b: *std.Build, entry: std.Io.Dir.Entry) !void {
    if (std.mem.endsWith(u8, entry.name, ".zig")) {
        const prefix = entry.name[0 .. entry.name.len - 4];
        const exe = b.addExecutable(.{
            .name = prefix,
            .root_module = b.createModule(.{
                .root_source_file = b.path(
                    try b.allocator.print("examples/{s}", .{entry.name}),
                ),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "vfglfw", .module = vfglfw_mod },
                },
            }),
        });
        const install = b.addInstallArtifact(exe, .{
            .dest_dir = .{
                .override = .{ .custom = "examples/" },
            },
        });
        const run = b.addRunArtifact(exe);
        run.addPassthruArgs();
        run.step.dependOn(&install.step);
        const step = b.step(
            try b.allocator.print("exp_{s}", .{prefix}),
            try b.allocator.print("Run example program '{s}'.", .{entry.name}),
        );
        step.dependOn(&run.step);
    }
}

fn build_dir_examples(b: *std.Build, dir: std.Io.Dir, entry: std.Io.Dir.Entry, io: std.Io) !void {
    const program_dir = try dir.openDir(io, entry.name, .{});
    defer program_dir.close(io);

    if (try existFile(io, program_dir, "build.zig")) {
        const cmd = b.addSystemCommand(&.{ "zig", "build" });
        cmd.addPassthruArgs();
        cmd.addArg("--cache-dir");
        cmd.addDirectoryArg2(b.path(
            try b.allocator.print(".zig-cache/examples/{s}", .{entry.name}),
        ), .{});
        cmd.addArg("--prefix");
        cmd.addDirectoryArg2(b.path(
            try b.allocator.print("zig-out/examples/{s}", .{entry.name}),
        ), .{});
        cmd.setCwd(b.path(try b.allocator.print("examples/{s}", .{entry.name})));
        const step = b.step(
            try b.allocator.print("exp_{s}", .{entry.name}),
            try b.allocator.print("Run example program '{s}'.", .{entry.name}),
        );
        step.dependOn(&cmd.step);
    } else if (try existFile(io, program_dir, "main.zig")) {
        const exe = b.addExecutable(.{
            .name = entry.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(
                    try b.allocator.print("examples/{s}/main.zig", .{entry.name}),
                ),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "vfglfw", .module = vfglfw_mod },
                },
            }),
        });
        const install = b.addInstallArtifact(exe, .{
            .dest_dir = .{
                .override = .{ .custom = "examples/" },
            },
        });
        const run = b.addRunArtifact(exe);
        run.addPassthruArgs();
        run.step.dependOn(&install.step);
        const step = b.step(
            try b.allocator.print("exp_{s}", .{entry.name}),
            try b.allocator.print("Run example program '{s}'.", .{entry.name}),
        );
        step.dependOn(&run.step);
    }
}

fn build_all_examples(b: *std.Build, io: std.Io) !void {
    b.dependOnDirectoryContents(b.path("examples/"));
    const dir = try b.root.openDir(io, "examples/", .{ .iterate = true });
    defer dir.close(io);

    var iter = dir.iterate();
    while (try iter.next(io)) |entry|
        switch (entry.kind) {
            .file => try build_file_examples(b, entry),
            .directory => try build_dir_examples(b, dir, entry, io),
            else => {},
        };
}
