const std = @import ("std");
const toolbox = @import ("toolbox");

fn update (builder: *std.Build, shaderc_path: [] const u8,
  dependencies: *const toolbox.Dependencies) !void
{
  std.fs.deleteTreeAbsolute (shaderc_path) catch |err|
  {
    switch (err)
    {
      error.FileNotFound => {},
      else => return err,
    }
  };

  try dependencies.clone (builder, "shaderc", shaderc_path);

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
    if ((entry.kind == .file) and ((
      std.mem.indexOf (u8, entry.basename, "test") != null) or
      toolbox.isCppHeader (entry.basename)))
        try std.fs.deleteFileAbsolute (try std.fs.path.join (
          builder.allocator, &.{ shaderc_path, entry.path, }));
  }

  try toolbox.clean (builder, &.{ "shaderc", }, &.{ ".inc", });
}

pub fn build (builder: *std.Build) !void
{
  const target = builder.standardTargetOptions (.{});
  const optimize = builder.standardOptimizeOption (.{});

  const shaderc_path =
    try builder.build_root.join (builder.allocator, &.{ "shaderc", });

  const dependencies = try toolbox.Dependencies.init (builder, "shaderc.zig",
  .{
     .toolbox = .{
       .name = "tiawl/toolbox",
       .host = toolbox.Repository.Host.github,
     },
     .glslang = .{
       .name = "tiawl/glslang.zig",
       .host = toolbox.Repository.Host.github,
     },
     .spirv = .{
       .name = "tiawl/spirv.zig",
       .host = toolbox.Repository.Host.github,
     },
   }, .{
     .shaderc = .{
       .name = "google/shaderc",
       .host = toolbox.Repository.Host.github,
     },
   });

  if (builder.option (bool, "update", "Update binding") orelse false)
    try update (builder, shaderc_path, &dependencies);

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
