# Win11 Toggle Rounded Corners
A simple utility to disable window rounded corners on Windows 11

Build with CMake and several tweaks.

Based on https://github.com/oberrich/win11-toggle-rounded-corners.

Compiled pass on MinGW Clang/GCC and Visual Studio MSVC 2019/2022.

### What‘s the difference between this repo and the source repo?

- UAC Manifest
- Upgrade to Zydis 4.0.0
- Transfer to CMake
- Address several problems
- Daemon mode that re-applies after `dwm.exe` restarts
- Linux MinGW-w64 cross-build helpers for Cloud Agents

### Build on Windows

```bat
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

Initialize the Zydis submodule first if needed:

```bat
git submodule update --init --recursive
```

### Build on Linux (MinGW-w64 cross compile)

Requires the POSIX MinGW thread model (`std::thread`), Ninja, and Wine for smoke tests.

```bash
bash scripts/cloud-agent-install.sh   # apt packages + Zydis submodule
bash scripts/build-mingw.sh           # Release PE32+ executable
```

Or configure manually:

```bash
cmake -S . -B cmake-build-mingw -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake
cmake --build cmake-build-mingw --parallel
```

Regression coverage for the MinGW path:

```bash
bash scripts/test-mingw-regression.sh
```

#### Wine notes

The cross-built `win11-toggle-rounded-corners.exe` is a 64-bit Windows GUI binary. Under Wine it prints the banner and options, then exits with `Failed to find dwm process.` because Desktop Window Manager is not present on Linux. That is the expected smoke-test result.

Ubuntu may suggest installing `wine32`. It is not required for this 64-bit executable; you can ignore the message.

### Usage

Run elevated (UAC / administrator):

```text
win11-toggle-rounded-corners.exe --disable
win11-toggle-rounded-corners.exe --enable
win11-toggle-rounded-corners.exe --disable --daemon
```

`--daemon` stays running and re-applies the preference when `dwm.exe` restarts. If neither `--enable` nor `--disable` is set with `--daemon`, it defaults to `--disable`.

### TO-DO

- [x] Daemon process (re-apply after `dwm.exe` restarts)
- [x] Address mem-leak (`CommandLineToArgvW`, process/module handles)
