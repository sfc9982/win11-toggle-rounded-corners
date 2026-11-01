#!/usr/bin/env bash
# Idempotent Cloud Agent install: MinGW-w64, Ninja, Wine, and Zydis.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y g++-mingw-w64-x86-64 ninja-build wine

# Prefer the POSIX thread model when the unsuffixed compiler name is used.
sudo update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix
sudo update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix

bash "${root}/scripts/lib/ensure-submodules.sh"
