# Agni

Agni is a learning-oriented statistics and machine-learning library written in
C++23 and built with Zig. The project exists to develop three skills that matter
for quantitative research: high-performance C++, numerical statistics, and the
ability to implement and validate machine-learning methods from first principles.

The C++ implementation is intentionally written by the repository owner. AI may
help organize the curriculum, frame exercises, identify concepts to review, and
describe behavioral tests, but it should not generate the algorithms or their
tests unless explicitly asked to depart from that rule.

## Current status

The repository currently contains the working build and dependency scaffold. It
does not yet contain Agni's statistical or machine-learning implementations.
The first implementation exercises are tracked in
[`learning/ROADMAP.md`](learning/ROADMAP.md), and completed learning sessions are
recorded in [`learning/LOG.md`](learning/LOG.md).

The existing executable is an HTTP and JSON integration demo. It verifies that
the dependency and cross-platform build setup works before the numerical library
is introduced.

## Dependencies

- **Eigen 5.0.1** for linear algebra, validation oracles, and selected optimized
  backends. Algorithms being studied should first be implemented independently
  and then compared with Eigen where appropriate.
- **Glaze 8.0.0** for JSON parsing and serialization. This remains a first-class
  project dependency so Agni can eventually persist configurations, experiment
  results, fitted models, and model metadata.
- **Standalone Asio 1.36.0** for networking used by Glaze's HTTP facilities.
- **OpenSSL 3.3.2** for HTTPS.

Glaze, Asio, and Eigen are header-only dependencies downloaded and
content-hash-verified by Zig. HTTPS uses the packaged OpenSSL dependency on
Unix-like targets. Windows builds use an installed OpenSSL because the packaged
OpenSSL build script does not currently support Windows.

## Intended layout

As the learning plan progresses, the repository will grow toward:

```text
include/agni/       Public library interfaces
src/                Implementations written by Akshay
tests/              Correctness and numerical tests written by Akshay
benchmarks/         Performance experiments
examples/           JSON, HTTP, and end-to-end examples
learning/           Roadmap, coaching contract, and learning log
```

The layout itself is part of the initial exercise. It has not been pre-created so
that library boundaries, translation units, test targets, and linkage remain
learning decisions rather than generated scaffolding.

## Build and run the current demo

Requirements:

- Zig 0.16.0
- A C++23-capable clangd for IDE support

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

On Windows, the build checks `-Dopenssl-root`, then `OPENSSL_ROOT_DIR`, and then
the Scoop default at `%USERPROFILE%\scoop\apps\openssl\current`:

```sh
zig build -Dhttps=true -Dopenssl-root="C:\Users\you\scoop\apps\openssl\current"
```

To build with packaged OpenSSL from Windows, target Linux explicitly:

```sh
zig build -Dhttps=true -Dtarget=x86_64-linux-gnu
```

## IDE support

Generate `compile_commands.json` with either command:

```sh
zig build cdb
zig build cmds
```

Pass the same non-default options used for the real build, for example:

```sh
zig build cmds -Dhttps=false
```

The compilation database uses `clang++` as its IDE-facing driver while the real
build continues to use Zig's Clang-based C++ frontend and linker. On Windows it
also includes Zig's bundled libc++ headers and configuration definitions.

For CLion:

1. Install the ZigBrains plugin and configure the Zig toolchain.
2. Open the repository as a compilation-database project.
3. Run `zig build cmds` and reload the compilation database.
4. Use the shared run configurations, `zig build run`, or `zig build debug`.

## Debugging and verification

Debug builds enable strict compiler warnings. Native Linux debug builds also use
address and undefined-behavior checks where supported. The learning workflow
requires every statistical feature to be derived, tested on adversarial inputs,
measured, and revisited through spaced retrieval before it is considered mastered.

See [`learning/DAILY_COACH.md`](learning/DAILY_COACH.md) for the exact contract
used by the scheduled learning coach.
