const std = @import("std");
const builtin = @import("builtin");
const zcc = @import("compile_commands");

const base_cxx_flags: []const []const u8 = &.{
    "-std=c++23",
};

const warning_flags: []const []const u8 = &.{
    "-Wall",
    "-Wextra",
    "-Wpedantic",
    "-Wnull-dereference",
    "-Wuninitialized",
    "-Wshadow",
    "-Wpointer-arith",
    "-Wstrict-aliasing",
    "-Wstrict-overflow=5",
    "-Wcast-align",
    "-Wconversion",
    "-Wsign-conversion",
    "-Wfloat-equal",
    "-Wformat=2",
    "-Wswitch-enum",
    "-Wmissing-declarations",
    "-Wunused",
    "-Wundef",
};

const runtime_check_flags: []const []const u8 = &.{
    "-fsanitize=array-bounds,null,alignment,unreachable,address",
    "-fstack-protector-strong",
    "-fno-omit-frame-pointer",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const https_option = b.option(
        bool,
        "https",
        "Enable HTTPS support with OpenSSL (default: true)",
    );
    const enable_https = https_option orelse true;
    const openssl_root = b.option(
        []const u8,
        "openssl-root",
        "OpenSSL installation root to use for Windows HTTPS builds",
    );

    // These libraries are header-only. build.zig.zon pins their source archives;
    // Zig only needs to expose their include directories to this C++ target.
    const glaze = b.dependency("glaze", .{});
    const asio = b.dependency("asio", .{});
    const eigen = b.dependency("eigen", .{});

    const windows_openssl_root = if (enable_https and target.result.os.tag == .windows)
        resolveWindowsOpenSslRoot(b, openssl_root)
    else
        null;

    const app = b.addExecutable(.{
        .name = "glaze-http-demo",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });
    configureApp(b, app, target, optimize, glaze, asio, eigen, enable_https, windows_openssl_root);

    const debug_app = b.addExecutable(.{
        .name = "debug",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = .Debug,
            .link_libcpp = true,
        }),
    });
    configureApp(b, debug_app, target, .Debug, glaze, asio, eigen, enable_https, windows_openssl_root);

    b.installArtifact(app);
    if (windows_openssl_root) |root| {
        installWindowsOpenSslRuntime(b, b.getInstallStep(), root);
    }

    const build_step = b.step("build", "Alias for install: build and install artifacts");
    build_step.dependOn(b.getInstallStep());

    const run_cmd = b.addRunArtifact(app);
    run_cmd.step.dependOn(b.getInstallStep());
    if (windows_openssl_root) |root| {
        configureWindowsOpenSslRunStep(b, run_cmd, root);
    }
    if (b.args) |args| run_cmd.addArgs(args);
    const run_step = b.step("run", "Build and run the Glaze HTTP + JSON example");
    run_step.dependOn(&run_cmd.step);

    const debug_install = b.addInstallArtifact(debug_app, .{});
    if (windows_openssl_root) |root| {
        installWindowsOpenSslRuntime(b, &debug_install.step, root);
    }
    const debug_step = b.step("debug", "Build the Debug executable for IDE debugging");
    debug_step.dependOn(&debug_install.step);

    zcc.options().driver = "clang++";
    var cdb_targets: std.ArrayList(*std.Build.Step.Compile) = .empty;
    cdb_targets.append(b.allocator, app) catch @panic("out of memory");
    cdb_targets.append(b.allocator, debug_app) catch @panic("out of memory");
    const cdb_step = zcc.createStep(
        b,
        "cdb",
        cdb_targets.toOwnedSlice(b.allocator) catch @panic("out of memory"),
    );
    const cmds_step = b.step("cmds", "Alias for cdb: generate compile_commands.json");
    cmds_step.dependOn(cdb_step);
}

fn configureApp(
    b: *std.Build,
    app: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    glaze: *std.Build.Dependency,
    asio: *std.Build.Dependency,
    eigen: *std.Build.Dependency,
    enable_https: bool,
    windows_openssl_root: ?[]const u8,
) void {
    const cxx_flags = getBuildFlags(target, optimize);

    app.root_module.addCSourceFile(.{
        .file = b.path("src/main.cpp"),
        .flags = cxx_flags,
    });
    app.root_module.addIncludePath(glaze.path("include"));
    app.root_module.addIncludePath(asio.path("asio/include"));
    app.root_module.addSystemIncludePath(eigen.path("."));
    app.root_module.addCMacro("ASIO_STANDALONE", "1");
    addWindowsIdeStdlibConfig(app, target);
    linkDebugSanitizerRuntime(b, app, target, optimize);

    if (enable_https) {
        if (target.result.os.tag == .windows) {
            linkWindowsOpenSsl(b, app, windows_openssl_root.?);
        } else {
            const openssl = b.dependency("openssl", .{
                .target = target,
                .optimize = optimize,
            });

            app.root_module.addCMacro("GLZ_ENABLE_SSL", "1");
            app.root_module.linkLibrary(openssl.artifact("openssl"));
        }
    }

    if (target.result.os.tag == .windows) {
        app.root_module.linkSystemLibrary("ws2_32", .{});
        app.root_module.linkSystemLibrary("mswsock", .{});
    }
}

fn addWindowsIdeStdlibConfig(
    app: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
) void {
    if (target.result.os.tag != .windows) return;

    const b = app.step.owner;
    const zig_lib = b.graph.zig_lib_directory;

    app.root_module.addSystemIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ zig_lib.path orelse ".", "libcxx", "include" }),
    });
    app.root_module.addSystemIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ zig_lib.path orelse ".", "libcxxabi", "include" }),
    });
    app.root_module.addSystemIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ zig_lib.path orelse ".", "include" }),
    });
    app.root_module.addSystemIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ zig_lib.path orelse ".", "libc", "include", "any-windows-any" }),
    });
    app.root_module.addSystemIncludePath(.{
        .cwd_relative = b.pathJoin(&.{ zig_lib.path orelse ".", "libunwind", "include" }),
    });

    app.root_module.addCMacro("__MSVCRT_VERSION__", "0xE00");
    app.root_module.addCMacro("_WIN32_WINNT", "0x0a00");
    app.root_module.addCMacro("_LIBCPP_ABI_VERSION", "1");
    app.root_module.addCMacro("_LIBCPP_ABI_NAMESPACE", "__1");
    app.root_module.addCMacro("_LIBCPP_HAS_THREADS", "1");
    app.root_module.addCMacro("_LIBCPP_HAS_MONOTONIC_CLOCK", "1");
    app.root_module.addCMacro("_LIBCPP_HAS_TERMINAL", "1");
    app.root_module.addCMacro("_LIBCPP_HAS_MUSL_LIBC", "0");
    app.root_module.addCMacro("_LIBCXXABI_DISABLE_VISIBILITY_ANNOTATIONS", "1");
    app.root_module.addCMacro("_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS", "1");
    app.root_module.addCMacro("_LIBCPP_HAS_VENDOR_AVAILABILITY_ANNOTATIONS", "0");
    app.root_module.addCMacro("_LIBCPP_HAS_FILESYSTEM", "1");
    app.root_module.addCMacro("_LIBCPP_HAS_RANDOM_DEVICE", "1");
    app.root_module.addCMacro("_LIBCPP_HAS_LOCALIZATION", "1");
    app.root_module.addCMacro("_LIBCPP_HAS_UNICODE", "1");
    app.root_module.addCMacro("_LIBCPP_HAS_WIDE_CHARACTERS", "1");
    app.root_module.addCMacro("_LIBCPP_HAS_NO_STD_MODULES", "1");
    app.root_module.addCMacro("_LIBCPP_PSTL_BACKEND_SERIAL", "1");
    app.root_module.addCMacro("_LIBCPP_HARDENING_MODE", "_LIBCPP_HARDENING_MODE_NONE");
}

fn getBuildFlags(
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) []const []const u8 {
    if (optimize != .Debug) {
        return base_cxx_flags;
    }

    return if (canUseDebugSanitizers(target.result, optimize))
        base_cxx_flags ++ warning_flags ++ runtime_check_flags
    else
        base_cxx_flags ++ warning_flags;
}

fn canUseDebugSanitizers(target: std.Target, optimize: std.builtin.OptimizeMode) bool {
    return optimize == .Debug and
        builtin.os.tag == .linux and
        target.os.tag == .linux and
        target.cpu.arch == builtin.cpu.arch;
}

fn linkDebugSanitizerRuntime(
    b: *std.Build,
    app: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    if (!canUseDebugSanitizers(target.result, optimize)) return;

    const asan_file = switch (target.result.cpu.arch) {
        .x86_64 => "libclang_rt.asan-x86_64.so",
        else => return,
    };
    const asan_name = switch (target.result.cpu.arch) {
        .x86_64 => "clang_rt.asan-x86_64",
        else => return,
    };
    const asan_path = std.mem.trimEnd(
        u8,
        b.run(&.{ "clang", b.fmt("-print-file-name={s}", .{asan_file}) }),
        "\r\n",
    );
    if (std.mem.eql(u8, asan_path, asan_file)) return;

    app.root_module.addLibraryPath(.{ .cwd_relative = std.fs.path.dirname(asan_path) orelse return });
    app.root_module.linkSystemLibrary(asan_name, .{ .needed = true });
}

fn linkWindowsOpenSsl(
    b: *std.Build,
    app: *std.Build.Step.Compile,
    root: []const u8,
) void {
    const include_dir = b.pathJoin(&.{ root, "include" });
    const lib_dir = b.pathJoin(&.{ root, "lib" });

    app.root_module.addCMacro("GLZ_ENABLE_SSL", "1");
    app.root_module.addSystemIncludePath(.{ .cwd_relative = include_dir });
    app.root_module.addLibraryPath(.{ .cwd_relative = lib_dir });
    app.root_module.linkSystemLibrary("libssl", .{});
    app.root_module.linkSystemLibrary("libcrypto", .{});
}

fn installWindowsOpenSslRuntime(
    b: *std.Build,
    step: *std.Build.Step,
    root: []const u8,
) void {
    const bin_dir = b.pathJoin(&.{ root, "bin" });

    step.dependOn(&b.addInstallFileWithDir(
        .{ .cwd_relative = b.pathJoin(&.{ bin_dir, "libssl-4-x64.dll" }) },
        .bin,
        "libssl-4-x64.dll",
    ).step);
    step.dependOn(&b.addInstallFileWithDir(
        .{ .cwd_relative = b.pathJoin(&.{ bin_dir, "libcrypto-4-x64.dll" }) },
        .bin,
        "libcrypto-4-x64.dll",
    ).step);
}

fn configureWindowsOpenSslRunStep(
    b: *std.Build,
    run_cmd: *std.Build.Step.Run,
    root: []const u8,
) void {
    const bin_dir = b.pathJoin(&.{ root, "bin" });

    run_cmd.addPathDir(bin_dir);
    run_cmd.setEnvironmentVariable("OPENSSL_CONF", b.pathJoin(&.{ bin_dir, "cnf", "openssl.cnf" }));
    run_cmd.setEnvironmentVariable("OPENSSL_MODULES", bin_dir);
}

fn resolveWindowsOpenSslRoot(b: *std.Build, configured_root: ?[]const u8) []const u8 {
    return configured_root orelse getEnvVar(b, "OPENSSL_ROOT_DIR") orelse defaultWindowsOpenSslRoot(b);
}

fn getEnvVar(b: *std.Build, name: []const u8) ?[]const u8 {
    return b.graph.environ_map.get(name);
}

fn defaultWindowsOpenSslRoot(b: *std.Build) []const u8 {
    const user_profile = getEnvVar(b, "USERPROFILE") orelse
        @panic("OPENSSL_ROOT_DIR is not set and USERPROFILE is unavailable; pass -Dopenssl-root=<path>");
    return b.pathJoin(&.{ user_profile, "scoop", "apps", "openssl", "current" });
}
