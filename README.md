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

### TO-DO

- [ ] Deamon process (avoid restart of dwm.exe)
- [ ] Address mem-leak
