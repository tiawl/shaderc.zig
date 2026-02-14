const std = @import("std");

const c = @cImport({
    @cInclude("shaderc/shaderc.h");
});

const Compilation = struct {
    const Result = struct {
        handle: c.shaderc_compilation_result_t,

        fn deinit(self: @This()) void {
            c.shaderc_result_release(self.handle);
        }

        fn getBytes(self: @This()) []const u8 {
            const length = c.shaderc_result_get_length(self.handle);
            const bytes = c.shaderc_result_get_bytes(self.handle);
            return std.mem.sliceAsBytes(bytes[0..length]);
        }

        fn getCompilationStatus(self: @This()) Compilation.Status {
            return @enumFromInt(c.shaderc_result_get_compilation_status(self.handle));
        }

        fn getErrorMessage(self: @This()) []const u8 {
            return std.mem.span(@as([*:0]const u8, @ptrCast(c.shaderc_result_get_error_message(self.handle))));
        }
    };

    const Status = enum(c.shaderc_compilation_status) {
        Success = c.shaderc_compilation_status_success,
        InvalidStage = c.shaderc_compilation_status_invalid_stage,
        CompilationError = c.shaderc_compilation_status_compilation_error,
        InternalError = c.shaderc_compilation_status_internal_error,
        NullResultObject = c.shaderc_compilation_status_null_result_object,
        InvalidAssembly = c.shaderc_compilation_status_invalid_assembly,
        ValidationError = c.shaderc_compilation_status_validation_error,
        TransformationError = c.shaderc_compilation_status_transformation_error,
        ConfigurationError = c.shaderc_compilation_status_configuration_error,
    };
};

const Compiler = struct {
    handle: c.shaderc_compiler_t,

    fn init() @This() {
        return .{
            .handle = c.shaderc_compiler_initialize(),
        };
    }

    fn deinit(self: @This()) void {
        c.shaderc_compiler_release(self.handle);
    }

    fn compileIntoSpv(self: @This(), allocator: std.mem.Allocator, source: []const u8, kind: ShaderKind, symbol: []const u8, options: CompileOptions) !Compilation.Result {
        // The "input_file_name" is a null-termintated string. It is used as a
        // tag to identify the source string in cases like emitting error
        // messages. It doesn't have to be a 'file name'.
        // The "entry_point_name" null-terminated string defines the name of
        // the entry point to associate with this GLSL source:
        return .{
            .handle = c.shaderc_compile_into_spv(self.handle, try allocator.dupeZ(u8, source), source.len, @intFromEnum(kind), try allocator.dupeZ(u8, symbol), "main", options.handle),
        };
    }
};

const CompileOptions = struct {
    handle: c.shaderc_compile_options_t,

    fn init() @This() {
        return .{
            .handle = c.shaderc_compile_options_initialize(),
        };
    }

    fn deinit(self: @This()) void {
        c.shaderc_compile_options_release(self.handle);
    }

    fn setOptimizationLevel(self: @This(), opt: OptimizationLevel) void {
        c.shaderc_compile_options_set_optimization_level(self.handle, @intFromEnum(opt));
    }

    fn setSourceLanguage(self: @This(), lang: SourceLanguage) void {
        c.shaderc_compile_options_set_source_language(self.handle, @intFromEnum(lang));
    }
};

const SourceLanguage = enum(c.shaderc_source_language) {
    GLSL = c.shaderc_source_language_glsl,
};

const OptimizationLevel = enum(c.shaderc_optimization_level) {
    zero = c.shaderc_optimization_level_zero,
    performance = c.shaderc_optimization_level_performance,
};

const ShaderKind = enum(c.shaderc_shader_kind) {
    fragment = c.shaderc_glsl_fragment_shader,
    vertex = c.shaderc_glsl_vertex_shader,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const compiler = Compiler.init();
    defer compiler.deinit();

    const options = CompileOptions.init();
    defer options.deinit();

    options.setSourceLanguage(.GLSL);
    options.setOptimizationLevel(.zero);

    const source =
        \\#version 450
        \\
        \\layout(location = 0) in vec2 in_position;
        \\
        \\void main() {
        \\  gl_Position = vec4(in_position, 0.0, 1.0);
        \\}
        \\
    ;

    const result = try compiler.compileIntoSpv(allocator, source, .vertex, "example", options);
    defer result.deinit();

    const status = result.getCompilationStatus();

    if (status != Compilation.Status.Success) {
        std.debug.print("{s}", .{result.getErrorMessage()});
        return error.CompilationFailed;
    }

    const bytes = result.getBytes();

    std.log.info("Compilation result bytes: \"{s}\"", .{bytes});
}
