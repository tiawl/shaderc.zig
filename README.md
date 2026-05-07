# shaderc.zig

This is a fork of [google/shaderc][1] packaged for [Zig][2]

## Why this fork ?

The intention under this fork is to package [google/shaderc][1] for [Zig][2]. So:
* Unnecessary files have been deleted,
* The build system has been replaced with `build.zig`,
* A cron runs every day to check [google/shaderc][1] and other dependencies. Then it updates this repository if a new release is available.

## How to use it

The goal of this repository is not to provide a [Zig][2] binding for [google/shaderc][1]. The point of this repository is to abstract the [google/shaderc][1] compilation process with [Zig][2] (which is not easy to maintain) to let you focus on your application. So you can use **shaderc.zig**:
- as raw (see into the `example` directory),
- as a daily updated interface for your [Zig][2] binding of [google/shaderc][1].

## Dependencies

The [Zig][2] part of this package requires the latest (0.16.0) or the master (0.17.0-dev) [Zig][2] release.

For other dependencies see [the build.zig.zon](https://github.com/tiawl/shaderc.zig/blob/stable/build.zig.zon)

## `zig build` options

These additional options have mainly been implemented for maintainability tasks but they maybe could be useful for edge usecases:
```
  -Dfetch   Update build.zig.zon then stop execution
  -Dupdate  Update binding
```

## License

This repository is not subject to a unique License:

The parts of this repository originated from this repository are dedicated to the public domain. See the LICENSE file for more details.

**For other parts, it is subject to the License restrictions their respective owners choosed. By design, the public domain code is incompatible with the License notion. In this case, the License prevails. So if you have any doubt about a file property, open an issue.**

[1]:https://github.com/google/shaderc
[2]:https://codeberg.org/ziglang/zig
