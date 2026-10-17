const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) !void {
    _ = b;
}

pub fn gladModule(
    b: *std.Build,
    glad: *std.Build.Dependency,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Optimize,
) *std.Build.Module {
    const translate_c = glad.builder.dependency("translate_c", .{});
    const glfw3_h: Translator = .init(translate_c, .{
        .c_source_file = glad.path("include/glad/glad.h"),
        .target = target,
        .optimize = optimize,
    });
    glfw3_h.addIncludePath(b.path("include/"));

    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.addCSourceFile(.{
        .file = glad.path("src/glad.c"),
        .language = .c,
    });
    mod.addIncludePath(glad.path("include/"));

    const lib = b.addLibrary(.{
        .name = "glad",
        .root_module = mod,
    });
    glfw3_h.mod.linkLibrary(lib);
    return glfw3_h.mod;
}
