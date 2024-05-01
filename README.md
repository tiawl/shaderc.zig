# shaderc.zig

This is a fork of [google/shaderc][1] packaged for [Zig][2]

## Why this fork ?

The intention under this fork is to package [google/shaderc][1] for [Zig][2]. So:
* Unnecessary files have been deleted,
* The build system has been replaced with `build.zig`,
* A cron runs every day to check [google/shaderc][1]. Then it updates this repository if a new release is available.

Here the repositories' version used by this fork:
* [google/shaderc](https://github.com/tiawl/shaderc.zig/blob/trunk/.versions/shaderc)

## CICD reminder

These repositories are automatically updated when a new release is available:
* [tiawl/spaceporn][3]

This repository is automatically updated when a new release is available from these repositories:
* [google/shaderc][1]
* [tiawl/toolbox][4]
* [tiawl/glslang.zig][5]
* [tiawl/spirv.zig][6]
* [tiawl/spaceporn-action-bot][7]
* [tiawl/spaceporn-action-ci][8]
* [tiawl/spaceporn-action-cd-ping][9]
* [tiawl/spaceporn-action-cd-pong][10]

## `zig build` options

These additional options have been implemented for maintainability tasks:
```
  -Dfetch   Update .versions folder and build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

The unprotected parts of this repository are under MIT License. For everything else, see with their respective owners.

[1]:https://github.com/google/shaderc
[2]:https://github.com/ziglang/zig
[3]:https://github.com/tiawl/spaceporn
[4]:https://github.com/tiawl/toolbox
[5]:https://github.com/tiawl/glslang.zig
[6]:https://github.com/tiawl/spirv.zig
[7]:https://github.com/tiawl/spaceporn-action-bot
[8]:https://github.com/tiawl/spaceporn-action-ci
[9]:https://github.com/tiawl/spaceporn-action-cd-ping
[10]:https://github.com/tiawl/spaceporn-action-cd-pong
