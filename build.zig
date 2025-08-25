const std = @import("std");
const toolbox_pkg = @import("toolbox");
const Toolbox = toolbox_pkg.Toolbox;

fn update(toolbox: *Toolbox, shaderc_path: []const u8) !void {
    std.fs.deleteTreeAbsolute(shaderc_path) catch |err| {
        switch (err) {
            error.FileNotFound => {},
            else => return err,
        }
    };

    try toolbox.clone(.shaderc, shaderc_path);

    var shaderc_dir = try std.fs.openDirAbsolute(shaderc_path, .{
        .iterate = true,
    });
    defer shaderc_dir.close();

    var it = shaderc_dir.iterate();
    while (try it.next()) |*entry| {
        if (!std.mem.startsWith(u8, entry.name, "libshaderc")) {
            try std.fs.deleteTreeAbsolute(toolbox.pathJoin(&.{
                shaderc_path, entry.name,
            }));
        }
    }

    var walker = try shaderc_dir.walk(toolbox.getBuilder().allocator);
    defer walker.deinit();

    while (try walker.next()) |*entry| {
        if ((entry.kind == .file) and ((std.mem.indexOf(u8, entry.basename, "test") != null) or toolbox_pkg.isCppHeader(entry.basename))) {
            try std.fs.deleteFileAbsolute(toolbox.pathJoin(&.{
                shaderc_path, entry.path,
            }));
        }
    }

    try toolbox.clean(&.{
        "shaderc",
    }, &.{
        ".inc",
    });
}

const FromZon = toolbox_pkg.Repositories(.{
    .toolbox, .glslang_zig, .spirv_zig,
});

const DuringExec = toolbox_pkg.Repositories(.{
    .shaderc,
});

pub fn build(builder: *std.Build) !void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    var toolbox = try Toolbox.init(FromZon, DuringExec, builder, optimize, .shaderc_zig, "0x3dd9ee4ee37ce998", &.{
        "shaderc",
    }, .{
        .toolbox = .{
            .name = "tiawl/toolbox",
            .host = .github,
            .ref = .tag,
        },
        .glslang_zig = .{
            .name = "tiawl/glslang.zig",
            .host = .github,
            .ref = .tag,
        },
        .spirv_zig = .{
            .name = "tiawl/spirv.zig",
            .host = .github,
            .ref = .tag,
        },
    }, .{
        .shaderc = .{
            .name = "google/shaderc",
            .host = .github,
            .ref = .tag,
        },
    });
    defer toolbox.deinit();

    const shaderc_path = try builder.build_root.join(builder.allocator, &.{
        "shaderc",
    });

    if (toolbox.getUpdate()) try update(&toolbox, shaderc_path);

    const lib = builder.addLibrary(.{
        .name = "shaderc",
        .root_module = std.Build.Module.create(builder, .{
            .root_source_file = builder.addWriteFiles().add("empty.zig", ""),
            .target = target,
            .optimize = optimize,
        }),
    });

    const flags = [_][]const u8{
        "-DENABLE_HLSL", "-fno-sanitize=undefined",
    };

    const glslang_dep = builder.dependency("glslang_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const spirv_dep = builder.dependency("spirv_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const glslang_compile_step = glslang_dep.artifact("glslang");
    const spirv_compile_step = spirv_dep.artifact("spirv");
    lib.linkLibrary(glslang_compile_step);
    lib.installLibraryHeaders(glslang_compile_step);
    lib.linkLibrary(spirv_compile_step);
    lib.installLibraryHeaders(spirv_compile_step);

    for ([_][]const u8{
        builder.pathJoin(&.{
            "shaderc", "libshaderc", "include",
        }),
        builder.pathJoin(&.{
            "shaderc", "libshaderc_util", "include",
        }),
    }) |include| {
        toolbox.addInclude(lib, include);
    }

    const libshaderc_path = builder.pathJoin(&.{
        shaderc_path, "libshaderc",
    });
    toolbox.addHeader(lib, builder.pathJoin(&.{
        libshaderc_path, "include", "shaderc",
    }), "shaderc", &.{
        ".h",
    });

    const libshaderc_util_path = builder.pathJoin(&.{
        shaderc_path, "libshaderc_util",
    });
    toolbox.addHeader(lib, builder.pathJoin(&.{
        libshaderc_util_path, "include", "libshaderc_util",
    }), "libshaderc_util", &.{
        ".h",
    });

    var dir: std.fs.Dir = undefined;
    var walker: std.fs.Dir.Walker = undefined;

    for ([_][]const u8{
        libshaderc_path, libshaderc_util_path,
    }) |path| {
        dir = try std.fs.openDirAbsolute(path, .{
            .iterate = true,
        });
        defer dir.close();

        walker = try dir.walk(builder.allocator);
        defer walker.deinit();

        while (try walker.next()) |*entry| {
            switch (entry.kind) {
                .file => {
                    if (toolbox_pkg.isCppSource(entry.basename)) {
                        try toolbox.addSource(lib, path, entry.path, &flags);
                    }
                },
                else => {},
            }
        }
    }

    builder.installArtifact(lib);
}
