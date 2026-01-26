const std = @import("std");

pub fn build(builder: *std.Build) !void {
    const target = builder.standardTargetOptions(.{});
    const optimize = .Debug;

    var exe = builder.addExecutable(.{
        .name = @tagName(@import("build.zig.zon").name),
        .root_module = std.Build.Module.create(builder, .{
            .root_source_file = .{
                .cwd_relative = try builder.build_root.join(builder.allocator, &.{ "src", "main.zig" }),
            },
            .target = target,
            .optimize = optimize,
        }),
    });

    var shaderc_dep = builder.dependency("shaderc_zig", .{
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibrary(shaderc_dep.artifact("shaderc"));

    builder.installArtifact(exe);
}
