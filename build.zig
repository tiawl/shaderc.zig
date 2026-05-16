const std = @import("std");
const build_zig_zon = @import("build.zig.zon");
const toolbox = @import("toolbox");
const VerboseBuilder = toolbox.VerboseBuilder;

fn updateFn(pkg_builder: *VerboseBuilder) !void {
    try pkg_builder.remove(&.{"shaderc"});
    try pkg_builder.make(&.{"shaderc"});
    try pkg_builder.make(&.{ "shaderc", "libshaderc" });
    try pkg_builder.make(&.{ "shaderc", "libshaderc_util" });

    const shaderc_dep = pkg_builder.verboseDependency("shaderc");
    var shaderc_builder = VerboseBuilder.initFromDependency(shaderc_dep);

    for ([_][]const u8{ "libshaderc", "libshaderc_util" }) |dir| {
        while (try shaderc_builder.walk(&.{dir})) |entry| {
            switch (entry.kind) {
                .file => if ((toolbox.isCHeader(entry.basename) or toolbox.isCOrCppSource(entry.basename) or toolbox.isIncludeFile(entry.basename)) and std.mem.indexOf(u8, entry.basename, "test") == null) {
                    try pkg_builder.copy(&.{ "shaderc", dir, entry.path }, &shaderc_builder, &.{ dir, entry.path });
                },
                .directory => try pkg_builder.make(&.{ "shaderc", dir, entry.path }),
                else => {},
            }
        }
    }
}

fn buildFn(pkg_builder: *VerboseBuilder) !void {
    const lib = pkg_builder.addLibrary("shaderc");

    const glslang_dep = pkg_builder.verboseDependency("glslang_zig");
    const spirv_dep = pkg_builder.verboseDependency("spirv_zig");
    const glslang_artifact = pkg_builder.artifact(glslang_dep, "glslang");
    const spirv_artifact = pkg_builder.artifact(spirv_dep, "spirv");

    pkg_builder.linkLibrary(lib, glslang_artifact);
    pkg_builder.linkLibrary(lib, spirv_artifact);
    pkg_builder.installLibraryHeaders(lib, glslang_artifact);
    pkg_builder.installLibraryHeaders(lib, spirv_artifact);

    pkg_builder.addInclude(lib, &.{ "shaderc", "libshaderc", "include" });
    pkg_builder.addInclude(lib, &.{ "shaderc", "libshaderc_util", "include" });

    while (try pkg_builder.walk(&.{ "shaderc", "libshaderc", "include", "shaderc" })) |*entry| {
        if (toolbox.isCHeader(entry.basename)) pkg_builder.installHeader(lib, &.{ "shaderc", "libshaderc", "include", "shaderc", entry.path }, &.{ "shaderc", entry.path });
    }

    while (try pkg_builder.walk(&.{ "shaderc", "libshaderc_util", "include", "libshaderc_util" })) |*entry| {
        if (toolbox.isCHeader(entry.basename)) pkg_builder.installHeader(lib, &.{ "shaderc", "libshaderc_util", "include", "libshaderc_util", entry.path }, &.{ "libshaderc_util", entry.path });
    }

    for ([_][]const u8{ "libshaderc", "libshaderc_util" }) |dir| {
        while (try pkg_builder.walk(&.{ "shaderc", dir })) |*entry| {
            switch (entry.kind) {
                .file => if (toolbox.isCppSource(entry.basename)) {
                    pkg_builder.addCSource(lib, &.{ "shaderc", dir, entry.path }, &.{ "-DENABLE_HLSL", "-fno-sanitize=undefined" });
                },
                else => {},
            }
        }
    }

    pkg_builder.installArtifact(lib);
}

pub fn build(builder: *std.Build) !void {
    var pkg_builder = try VerboseBuilder.init(builder, build_zig_zon, buildFn, updateFn);

    try pkg_builder.fetch(build_zig_zon, pkg_builder.ptrCwd());
    try pkg_builder.update();
    try pkg_builder.build();
}
