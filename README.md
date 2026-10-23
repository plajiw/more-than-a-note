# more-than-a-note

more-than-a-note is the working name for a desktop notebook for students and teachers, planned to be free and open source. It aims to combine movable text, handwriting, images and diagrams on pages organized into notebooks and sections. The product is planned to work offline, with local files and export options.

## Building

Requirements:

- CMake 3.25+ and Ninja
- A C++20 compiler (MSVC 2022, GCC 11+ or Clang 14+)
- Qt 6.8+ with the Quick, QuickControls2 and Sql modules (desktop app only)

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
