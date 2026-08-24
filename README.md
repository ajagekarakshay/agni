# C++ HTTP + JSON with Glaze, built by Zig

This example uses Zig 0.16.0 as both the build system and C++ compiler. It uses
Glaze 8.0.0 for HTTP and JSON, standalone Asio 1.36.0 for networking, and
OpenSSL for HTTPS. No CMake, Make, Ninja, CPR, or libcurl is involved.

The demo performs an HTTP GET, parses the JSON body directly into a C++ struct,
prints its fields, and serializes the struct back to JSON.

## Requirements

- Zig 0.16.0
- A C++23-capable clangd for IDE support

Glaze and standalone Asio are downloaded and content-hash-verified by Zig.
HTTPS builds use the packaged OpenSSL dependency on Unix-like targets. On
Windows, the build links against an installed OpenSSL because the packaged
OpenSSL build script does not yet support Windows.

## Build and run

```sh
zig build --fetch
zig build
zig build run
zig build run -- https://jsonplaceholder.typicode.com/todos/2
```

For an HTTP-only build that does not require OpenSSL:

```sh
zig build -Dhttps=false
zig build run -Dhttps=false -- http://127.0.0.1:8080/todo
```

On Windows, the build uses `-Dopenssl-root`, then `OPENSSL_ROOT_DIR`, then the
Scoop default at `%USERPROFILE%\scoop\apps\openssl\current`:

```sh
zig build -Dhttps=true -Dopenssl-root="C:\Users\you\scoop\apps\openssl\current"
```

To build with packaged OpenSSL from Windows, target Linux explicitly:

```sh
zig build -Dhttps=true -Dtarget=x86_64-linux-gnu
```

## Generate compile_commands.json

```sh
zig build cdb
```

The template-compatible alias is also available:

```sh
zig build cmds
```

If you use non-default build options, pass the same options to this command:

```sh
zig build cmds -Dhttps=false
```

This writes `compile_commands.json` in the project root. Open this directory in
VS Code with the clangd extension, Neovim, CLion compilation-database mode, or
another clangd-based editor.

The database uses `clang++` as its IDE-facing driver. The real build continues
to use Zig's Clang-based C++ frontend and linker.

On Windows, the generated database includes Zig's bundled libc++ headers and
configuration defines so clangd/CLion can resolve `std::` symbols.

## JetBrains CLion setup

1. Install the ZigBrains plugin.
2. Configure the Zig toolchain in ZigBrains settings.
3. Open this directory as a compilation database project.
4. Generate the database with `zig build cmds`.
5. Use the shared `.run` configurations, or create a Zig build run
   configuration manually:
   - Build steps: `build` for compile/install only, or `run` to execute the app
   - Program arguments: optional URL after `--`, for example
     `-- https://jsonplaceholder.typicode.com/todos/2`
   - Debug build steps: `debug`
   - Debug output executable: `<project>/zig-out/bin/debug.exe` on Windows, or
     `<project>/zig-out/bin/debug` on Unix-like systems

If CLion still does not show `std::` IntelliSense, reload the compilation
database after regenerating `compile_commands.json`.

## How build.zig replaces CMake

Glaze and Asio are header-only, so there are no external source libraries to
compile. Zig exposes their headers to the application target:

```zig
const glaze = b.dependency("glaze", .{});
const asio = b.dependency("asio", .{});

app.root_module.addIncludePath(glaze.path("include"));
app.root_module.addIncludePath(asio.path("asio/include"));
app.root_module.addCMacro("ASIO_STANDALONE", "1");
```

HTTPS additionally enables Glaze's SSL code and links OpenSSL. Windows uses the
installed OpenSSL import libraries:

```zig
app.root_module.addSystemIncludePath(.{ .cwd_relative = openssl_include_dir });
app.root_module.addLibraryPath(.{ .cwd_relative = openssl_lib_dir });
app.root_module.linkSystemLibrary("libssl", .{});
app.root_module.linkSystemLibrary("libcrypto", .{});
```

Unix-like targets use the Zig package:

```zig
const openssl = b.dependency("openssl", .{
    .target = target,
    .optimize = optimize,
});

app.root_module.addCMacro("GLZ_ENABLE_SSL", "1");
app.root_module.linkLibrary(openssl.artifact("openssl"));
```

The application itself is compiled as C++23 because Glaze's current networking
API uses features such as `std::expected`:

```zig
app.root_module.addCSourceFile(.{
    .file = b.path("src/main.cpp"),
    .flags = &.{"-std=c++23"},
});
app.root_module.linkSystemLibrary("c++", .{});
```

## JSON flow

Glaze reflects aggregate structs automatically; no schema macros are needed:

```cpp
struct Todo {
    int userId{};
    int id{};
    std::string title{};
    bool completed{};
};

Todo todo{};
auto error = glz::read_json(todo, response->response_body);
auto json = glz::write_json(todo);
```

For field renaming, private data, enums-as-strings, validation, or custom
serialization, add `glz::meta<T>` metadata.

## Important caveats

- Glaze's networking API is usable but explicitly described upstream as under
  active development. Pin a version and review release notes before upgrading.
- Glaze core JSON has no external runtime dependency, but networking requires
  Asio, and HTTPS requires OpenSSL.
- Windows HTTPS links against an installed OpenSSL. Unix-like HTTPS builds use
  the pinned OpenSSL Zig package.
- Regenerate `compile_commands.json` whenever flags, dependencies, defines, or
  source files change.
