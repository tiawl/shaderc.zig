# shaderc.zig

This is a fork of [google/shaderc][1] packaged for [Zig][2]

## Why this fork ?

The intention under this fork is to package [google/shaderc][1] for [Zig][2]. So:
* Unnecessary files have been deleted,
* The build system has been replaced with `build.zig`,
* A cron runs every day to check [google/shaderc][1]. Then it updates this repository if a new release is available.

## How to use it

The goal of this repository is not to provide a [Zig][2] binding for [google/shaderc][1]. There are at least as many legit ways as possible to make a binding as there are active accounts on Github. So you are not going to find an answer for this question here. The point of this repository is to abstract the [google/shaderc][1] compilation process with [Zig][2] (which is not new comers friendly and not easy to maintain) to let you focus on your application. So you can use **shaderc.zig**:
- as raw (no available example, open an issue if you are interested in, we will be happy to help you),
- as a daily updated interface for your [Zig][2] binding of [google/shaderc][1] (see [here][11] for a private usage).

## Dependencies

The [Zig][2] part of this package is relying on the latest [Zig][2] release (0.13.0) and will only be updated for the next one (so for the 0.14.0).

Here the repositories' version used by this fork:
* [google/shaderc](https://github.com/tiawl/shaderc.zig/blob/trunk/.references/shaderc)

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
  -Dfetch   Update .references folder and build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

This repository is not subject to a unique License:

The parts of this repository originated from this repository are dedicated to the public domain. See the LICENSE file for more details.

**For other parts, it is subject to the License restrictions their respective owners choosed. By design, the public domain code is incompatible with the License notion. In this case, the License prevails. So if you have any doubt about a file property, open an issue.**

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
[11]:https://github.com/tiawl/spaceporn/blob/trunk/src/compiler/bindings/shaderc/shaderc.zig
