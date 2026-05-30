const std = @import("std");

fn addIncludePathsToTranslateC(translate_c: *std.Build.Step.TranslateC, lib: *std.Build.Step.Compile) void {
    for (lib.root_module.include_dirs.items) |*included| {
        switch (included.*) {
            .path => translate_c.addIncludePath(included.path),
            .config_header_step => translate_c.addConfigHeader(included.config_header_step),
            .path_system => translate_c.addSystemIncludePath(included.path_system),
            .other_step => addIncludePathsToTranslateC(translate_c, included.other_step),
            else => unreachable,
        }
    }
}

pub fn build(builder: *std.Build) !void {
    const target = builder.standardTargetOptions(.{});
    const optimize = .Debug;

    const translate_c = builder.addTranslateC(.{
        .root_source_file = builder.path(builder.pathJoin(&.{
            "src", "c.h",
        })),
        .target = target,
        .optimize = optimize,
    });

    var shaderc_dep = builder.dependency("shaderc_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const shaderc_artifact = shaderc_dep.artifact("shaderc");

    addIncludePathsToTranslateC(translate_c, shaderc_artifact);

    const c_module = translate_c.createModule();
    c_module.linkLibrary(shaderc_artifact);

    const exe = builder.addExecutable(.{
        .name = @tagName(@import("build.zig.zon").name),
        .root_module = std.Build.Module.create(builder, .{
            .root_source_file = .{
                .cwd_relative = if (@hasField(std.Build, "build_root")) try builder.build_root.join(builder.allocator, &.{ "src", "main.zig" }) else if (@hasField(std.Build, "root")) try builder.root.root_dir.join(builder.allocator, &.{ "src", "main.zig" }) else unreachable,
            },
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "c",
                    .module = c_module,
                },
            },
        }),
    });

    builder.installArtifact(exe);
}
