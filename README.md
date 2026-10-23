# more-than-a-note

more-than-a-note is the working name for a desktop notebook for students and teachers, planned to be free and open source. It aims to combine movable text, handwriting, images and diagrams on pages organized into notebooks and sections. The product is planned to work offline, with local files and export options.

## Building

Requirements:

- CMake 3.25+ and Ninja
- A C++20 compiler (MSVC 2022, GCC 11+ or Clang 14+)
- Qt 6.8+ with the Quick, QuickControls2, Sql and Svg modules (desktop app only)

If Qt is not on your default search path, tell CMake where it is, for example
`-DCMAKE_PREFIX_PATH=C:/Qt/6.8.3/msvc2022_64`, or set the `CMAKE_PREFIX_PATH`
environment variable.

With MSYS2 Qt on Windows, put `C:\msys64\ucrt64\bin` first on `PATH` before
configuring. Otherwise Qt's tools may load DLLs from another MinGW install and
fail with exit code `0xc0000139`.

```sh
cmake --preset debug        # desktop app + tests
cmake --build --preset debug
ctest --preset debug
```

To build only the core library and its tests, without Qt, use the `core` preset
instead of `debug`.

## Packaging

To build a portable Windows ZIP that runs on PCs without Qt installed (it
bundles the Qt DLLs, plugins, QML modules and runtime libraries):

```sh
cmake --preset release
cmake --build --preset release --target package
# cmake --build --preset release --target package
# cmake --install build/release --prefix build/dist

```

The ZIP is written to `build/release/`. To get an unpacked folder instead, run
`cmake --install build/release --prefix dist`. On Linux the app uses the
distribution's Qt packages.

## Docker

To check that the project builds and its tests pass on a clean Linux system
(Debian, Qt 6.8):

```sh
docker build -t more-than-a-note .
```

Docker only builds and runs the tests. To run the app and work with the GUI,
use a native build.
