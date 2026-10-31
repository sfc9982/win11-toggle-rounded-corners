#!/usr/bin/env bash
# Configure and build the Windows executable with MinGW-w64.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

git submodule update --init --recursive

cmake -S . -B cmake-build-mingw -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64-x86_64.cmake
cmake --build cmake-build-mingw --parallel

echo "Built ${root}/cmake-build-mingw/win11-toggle-rounded-corners.exe"
