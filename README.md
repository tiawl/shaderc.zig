# shaderc.zig

This is a fork of [google/shaderc](https://github.com/google/shaderc) packaged for @ziglang

## Why this fork ?

The intention under this fork is to package [google/shaderc](https://github.com/google/shaderc) for @ziglang. So:
* Unnecessary files have been deleted,
* The build system has been replaced with `build.zig`,
* A cron runs every day to check [google/shaderc](https://github.com/google/shaderc). Then it updates this repository if a new release is available.

Here the repositories' version used by this fork:
* [google/shaderc](https://github.com/tiawl/shaderc.zig/blob/trunk/.versions/shaderc)

## CICD reminder

These repositories are automatically updated when a new release is available:
* [tiawl/spaceporn](https://github.com/tiawl/spaceporn)

This repository is automatically updated when a new release is available from these repositories:
* [google/shaderc](https://github.com/google/shaderc)
* [tiawl/toolbox](https://github.com/tiawl/toolbox)
* [tiawl/glslang.zig](https://github.com/tiawl/glslang.zig)
* [tiawl/spirv.zig](https://github.com/tiawl/spirv.zig)
* [tiawl/spaceporn-action-bot](https://github.com/tiawl/spaceporn-action-bot)
* [tiawl/spaceporn-action-ci](https://github.com/tiawl/spaceporn-action-ci)
* [tiawl/spaceporn-action-cd-ping](https://github.com/tiawl/spaceporn-action-cd-ping)
* [tiawl/spaceporn-action-cd-pong](https://github.com/tiawl/spaceporn-action-cd-pong)

## `zig build` options

These additional options have been implemented for maintainability tasks:
```
  -Dfetch   Update .versions folder and build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

The unprotected parts of this repository are under MIT License. For everything else, see with their respective owners.
