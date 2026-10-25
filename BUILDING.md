# Building more-than-a-note

This guide covers Windows, Linux and macOS. Each section says whether the steps
have been verified on that system.

## What you need on every system

- CMake 3.25 or newer and Ninja
- A C++20 compiler: GCC 11+, Clang 14+ or MSVC 2022
- Qt 6.8 or newer with these modules: Base (Core, Gui, Sql with the SQLite
  driver, Test), Declarative (Qml, Quick, QuickControls2, QuickTest) and Svg

Fonts and icons are bundled in the repository, so nothing else is downloaded.

## Build presets

All systems use the same presets from `CMakePresets.json`:

| Preset    | What it builds                                    | Output folder     |
| --------- | ------------------------------------------------- | ----------------- |
| `debug`   | App and tests, debug build                        | `build/debug`     |
| `release` | App and tests, optimized build                    | `build/release`   |
| `core`    | Only the core library and its tests, without Qt   | `build/core`      |

The cycle is always the same:

```sh
cmake --preset release           # configure (first time, or after adding files)
cmake --build --preset release   # compile
ctest --preset release           # run the tests
```

Run `cmake --preset ...` again when you add or remove a QML file, a font or
icon, or change a CMake option. Otherwise `cmake --build` is enough.

## Windows

### Option A: MSYS2 (verified)

This is the setup used in development.

1. Install [MSYS2](https://www.msys2.org/) in `C:\msys64`.
2. In the **MSYS2 UCRT64** terminal, install the tools and Qt:

   ```sh
   pacman -S --needed mingw-w64-ucrt-x86_64-toolchain mingw-w64-ucrt-x86_64-cmake \
       mingw-w64-ucrt-x86_64-ninja mingw-w64-ucrt-x86_64-qt6-base \
       mingw-w64-ucrt-x86_64-qt6-declarative mingw-w64-ucrt-x86_64-qt6-svg
   ```

3. In PowerShell, from the repository root:

   ```powershell
   $env:PATH = "C:\msys64\ucrt64\bin;$env:PATH"   # once per terminal
   cmake --preset release
   cmake --build --preset release
   ctest --preset release
   ```

   `C:\msys64\ucrt64\bin` must come **first** on `PATH`. If another MinGW (from
   Git, an old MinGW install, etc.) comes first, Qt's tools load the wrong DLLs
   and fail with exit code `0xc0000139`.

4. Create the runnable folder and open the app:

   ```powershell
   cmake --install build/release --prefix build/dist
   & ".\build\dist\bin\more_than_a_note.exe"
   ```

   `build\dist` contains the app with every DLL it needs, so it also runs on a
   PC without MSYS2. The prompt returns immediately because the app is a window
   application, not a console one.

### Option B: official Qt installer and Visual Studio (not verified yet)

1. Install Visual Studio 2022 with the "Desktop development with C++" workload
   (it includes CMake and Ninja).
2. Install Qt 6.8+ for MSVC 2022 64-bit with the
   [Qt Online Installer](https://www.qt.io/download-qt-installer-oss), including
   the Qt Svg module.
3. Open the **x64 Native Tools Command Prompt for VS 2022** and run:

   ```bat
   cmake --preset release -DCMAKE_PREFIX_PATH=C:/Qt/6.8.3/msvc2022_64
   cmake --build --preset release
   ctest --preset release
   cmake --install build/release --prefix build/dist
   ```

   Adjust the Qt path to the version you installed.

## Linux

The app uses the distribution's Qt packages. Qt 6.8 or newer is required, so
older releases (for example Ubuntu 24.04, which ships Qt 6.4) do not work.

### Debian 13 "trixie" (verified in Docker)

```sh
sudo apt install build-essential cmake ninja-build \
    qt6-base-dev qt6-declarative-dev qt6-declarative-dev-tools qt6-svg-dev \
    libqt6sql6-sqlite libgl-dev \
    qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts \
    qml6-module-qtquick-window qml6-module-qtqml-workerscript qml6-module-qtquick-templates
cmake --preset release
cmake --build --preset release
ctest --preset release
./build/release/more_than_a_note
```

Ubuntu 25.04 or newer should work with the same packages (not verified).

### Fedora 41 or newer (not verified yet)

```sh
sudo dnf install gcc-c++ cmake ninja-build \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtsvg-devel
cmake --preset release && cmake --build --preset release && ctest --preset release
./build/release/more_than_a_note
```

### Arch Linux (not verified yet)

```sh
sudo pacman -S --needed base-devel cmake ninja qt6-base qt6-declarative qt6-svg
cmake --preset release && cmake --build --preset release && ctest --preset release
./build/release/more_than_a_note
```

### Any system with Docker (verified)

To check that the project builds and its tests pass on a clean Debian, without
installing anything else:

```sh
docker build -t more-than-a-note .
```

Docker only builds and runs the tests; it does not open the app.

## macOS (not verified yet)

1. Install the Xcode command line tools: `xcode-select --install`.
2. Install the tools and Qt with [Homebrew](https://brew.sh/):

   ```sh
   brew install cmake ninja qt
   ```

3. Build, test and open:

   ```sh
   cmake --preset release -DCMAKE_PREFIX_PATH="$(brew --prefix qt)"
   cmake --build --preset release
   ctest --preset release
   open build/release/more_than_a_note.app
   ```

On macOS the app uses the system menu bar.

## Packaging

| System  | Command                                             | Result                                                  |
| ------- | --------------------------------------------------- | ------------------------------------------------------- |
| Windows | `cmake --build --preset release --target package`   | ZIP with Qt in `build/release/`; clean-PC test pending |
| Windows | `cmake --install build/release --prefix build/dist` | Same content as an unpacked folder                      |
| Linux   | `cmake --build --preset release --target package`   | `.tar.gz` with the app only; requires Qt 6.8+ at runtime |
| macOS   | `cmake --install build/release --prefix build/dist` | `.app` bundle with Qt inside (not verified yet)         |

A portable Linux package (AppImage or Flatpak) is planned for later. The Linux
archive does not include Qt libraries or platform plugins. The E2 smoke test
extracted the archive and ran its executable with Qt 6.8.3 available locally;
it created a notebook and reopened it after restarting the app. To repeat that
test with a local Qt SDK, set `LD_LIBRARY_PATH` to its `lib` directory and
`QT_PLUGIN_PATH` to its `plugins` directory before launching the extracted
`bin/more_than_a_note`. Keep `XDG_DATA_HOME` and `XDG_CONFIG_HOME` pointed at
temporary directories to avoid using your personal notebooks.

The Linux CI workflow runs the Release desktop suite with GCC and the `core`
suite with Clang in a Debian container. The Windows workflow runs the same
Release desktop and core tests with MSYS2 UCRT64 and Qt. Both workflows run on
push, pull request and manual dispatch. A green CI run verifies build and
automated tests on that runner; it does not replace the manual Windows screen
reader, mixed-DPI or clean-PC ZIP checks. Locally,
`tests/fixtures/make_e2_fixture.py XDG_DATA_HOME` creates the
E2 notebook data for manual interface and accessibility checks. The Qt Quick
Test workspace suite uses its own temporary profile. `QT_SCALE_FACTOR=1.25`
and `1.5` exercise simulated scaling; they do not replace a test with two
physical monitors at different scale factors.

## App options

| Option         | Effect                                      |
| -------------- | ------------------------------------------- |
| `--gallery`    | Opens the visual gallery next to the app    |
| `--page-model-demo` | Shows the temporary E3.5 page-model demonstration; its objects are kept only in memory |
| `--editor-probe` | Shows the E4.1 text and mouse-ink composition experiment on a selected page; changes are temporary |
| `--editor-model-demo` | Opens the E4.3 proof with two plain-text fields and mouse ink backed by the selected notebook; save text with Ctrl+S or the button, while each completed stroke saves immediately |
| `--scale=1.5`  | Simulates another display scale             |

## Troubleshooting

| Problem                                                 | Cause and fix                                                                                       |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `Qt 6.8+ was not found` when configuring                | Qt is not on the search path. Pass `-DCMAKE_PREFIX_PATH=<Qt folder>` or use the `core` preset.       |
| Exit code `0xc0000139` on Windows                       | Wrong DLLs on `PATH`. Put `C:\msys64\ucrt64\bin` first.                                              |
| The app flashes and closes on Windows                   | You opened `build\release\...exe` or the exe inside the ZIP without extracting it. Use `build\dist`. |
| Icons do not appear                                     | The Qt Svg module is missing. Install it (see your system above).                                   |
| `module "QtQuick.Controls" is not installed` on Linux   | Install the `qml6-module-*` packages listed for your distribution.                                  |
| The window does not appear                              | It may have opened on another monitor; check the taskbar.                                           |
