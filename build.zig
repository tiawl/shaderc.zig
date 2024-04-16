const std = @import ("std");
const toolbox = @import ("toolbox");
const pkg = .{ .name = "shaderc.zig", .version = "2024.0.0", };

fn update (builder: *std.Build, shaderc_path: [] const u8) !void
{
  std.fs.deleteTreeAbsolute (shaderc_path) catch |err|
  {
    switch (err)
    {
      error.FileNotFound => {},
      else => return err,
    }
  };

  try toolbox.clone (builder, "https://github.com/google/shaderc.git",
    "v" ++ pkg.version [0 .. pkg.version.len - 2], shaderc_path);

  var shaderc_dir =
    try std.fs.openDirAbsolute (shaderc_path, .{ .iterate = true, });
  defer shaderc_dir.close ();

  var it = shaderc_dir.iterate ();
  while (try it.next ()) |*entry|
  {
    if (!std.mem.startsWith (u8, entry.name, "libshaderc"))
      try std.fs.deleteTreeAbsolute (try std.fs.path.join (builder.allocator,
        &.{ shaderc_path, entry.name, }));
  }

  var walker = try shaderc_dir.walk (builder.allocator);
  defer walker.deinit ();

  while (try walker.next ()) |*entry|
  {
    if (entry.kind == .file and ((toolbox.isCppSource (
      entry.basename) and
      std.mem.indexOf (u8, entry.basename, "test") != null) or
      (!toolbox.isCppSource (entry.basename) and
      !toolbox.isCHeader (entry.basename) and
      !std.mem.endsWith (u8, entry.basename, ".inc"))))
        try std.fs.deleteFileAbsolute (try std.fs.path.join (
          builder.allocator, &.{ shaderc_path, entry.path, }));
  }

  var flag = true;

  while (flag)
  {
    flag = false;

    walker = try shaderc_dir.walk (builder.allocator);
    defer walker.deinit ();

    while (try walker.next ()) |*entry|
    {
      if (entry.kind == .directory)
      {
        std.fs.deleteDirAbsolute (try std.fs.path.join (builder.allocator,
          &.{ shaderc_path, entry.path, })) catch |err|
        {
          if (err == error.DirNotEmpty) continue else return err;
        };
        flag = true;
      }
    }
  }
}

pub fn build (builder: *std.Build) !void
{
  const target = builder.standardTargetOptions (.{});
  const optimize = builder.standardOptimizeOption (.{});

  const shaderc_path =
    try builder.build_root.join (builder.allocator, &.{ "shaderc", });

  if (builder.option (bool, "update", "Update binding") orelse false)
    try update (builder, shaderc_path);

  const lib = builder.addStaticLibrary (.{
    .name = "shaderc",
    .root_source_file = builder.addWriteFiles ().add ("empty.c", ""),
    .target = target,
    .optimize = optimize,
  });

  const flags = [_][] const u8 { "-DENABLE_HLSL", "-fno-sanitize=undefined", };

  const glslang_dep = builder.dependency ("glslang", .{
    .target = target,
    .optimize = optimize,
  });

  const spirv_dep = builder.dependency ("spirv", .{
    .target = target,
    .optimize = optimize,
  });

  const glslang_compile_step = glslang_dep.artifact ("glslang");
  const spirv_compile_step = spirv_dep.artifact ("spirv");
  lib.linkLibrary (glslang_compile_step);
  lib.installLibraryHeaders (glslang_compile_step);
  lib.linkLibrary (spirv_compile_step);
  lib.installLibraryHeaders (spirv_compile_step);

  for ([_][] const u8 {
    try std.fs.path.join (builder.allocator,
      &.{ "shaderc", "libshaderc", "include", }),
    try std.fs.path.join (builder.allocator,
      &.{ "shaderc", "libshaderc_util", "include", }),
  }) |include| toolbox.addInclude (lib, include);

  const libshaderc_path = try std.fs.path.join (builder.allocator,
    &.{ shaderc_path, "libshaderc", });
  toolbox.addHeader (lib, try std.fs.path.join (builder.allocator,
    &.{ libshaderc_path, "include", "shaderc", }), "shaderc", &.{ ".h", });

  const libshaderc_util_path = try std.fs.path.join (builder.allocator,
    &.{ shaderc_path, "libshaderc_util", });
  toolbox.addHeader (lib, try std.fs.path.join (builder.allocator,
    &.{ libshaderc_util_path, "include", "libshaderc_util", }),
      "libshaderc_util", &.{ ".h", });

  var dir: std.fs.Dir = undefined;
  var walker: std.fs.Dir.Walker = undefined;

  for ([_][] const u8 { libshaderc_path, libshaderc_util_path, }) |path|
  {
    dir = try std.fs.openDirAbsolute (path, .{ .iterate = true, });
    defer dir.close ();

    walker = try dir.walk (builder.allocator);
    defer walker.deinit ();

    while (try walker.next ()) |*entry|
    {
      switch (entry.kind)
      {
        .file => {
          if (toolbox.isCppSource (entry.basename))
            try toolbox.addSource (lib, path, entry.path, &flags);
        },
        else => {},
      }
    }
  }

  builder.installArtifact (lib);
}
