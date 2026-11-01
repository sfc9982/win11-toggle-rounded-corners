#!/usr/bin/env bash
# Regression coverage for the three Sourcery blockers on the MinGW path.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

pass=0
fail=0

ok() {
  echo "PASS: $1"
  pass=$((pass + 1))
}

die() {
  echo "FAIL: $1" >&2
  fail=$((fail + 1))
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: missing required command: $1" >&2
    exit 1
  }
}

require_cmd cmake
require_cmd ninja
require_cmd flock
require_cmd git
require_cmd wine
require_cmd x86_64-w64-mingw32-g++-posix

build_dir="${root}/cmake-build-mingw-regression"
install_prefix="${root}/output/mingw-regression"
rm -rf "${build_dir}" "${install_prefix}"

echo "== 1) Out-of-repo install + submodule ensure =="
# Start from a missing Zydis checkout, then invoke the helper and the
# cloud-agent install script while the caller's cwd is outside the repo.
git -C "${root}" submodule deinit -f deps/zydis >/dev/null 2>&1 || true
rm -rf "${root}/deps/zydis"
mkdir -p "${root}/deps/zydis"
(
  cd /tmp
  bash "${root}/scripts/lib/ensure-submodules.sh"
)
if [[ -f "${root}/deps/zydis/CMakeLists.txt" ]] \
  && [[ -f "${root}/deps/zydis/dependencies/zycore/CMakeLists.txt" ]]; then
  ok "ensure-submodules.sh succeeds when invoked from /tmp"
else
  die "Zydis/Zycore missing after out-of-repo ensure-submodules.sh"
fi

git -C "${root}" submodule deinit -f deps/zydis >/dev/null 2>&1 || true
rm -rf "${root}/deps/zydis"
mkdir -p "${root}/deps/zydis"
(
  cd /tmp
  bash "${root}/scripts/cloud-agent-install.sh"
)
if [[ -f "${root}/deps/zydis/CMakeLists.txt" ]] \
  && [[ -f "${root}/deps/zydis/dependencies/zycore/CMakeLists.txt" ]]; then
  ok "cloud-agent-install.sh checks out Zydis when invoked from /tmp"
else
  die "Zydis missing after out-of-repo cloud-agent-install.sh"
fi

echo "== 2) Concurrent submodule initialization =="
git -C "${root}" submodule deinit -f deps/zydis >/dev/null 2>&1 || true
rm -rf "${root}/deps/zydis"
mkdir -p "${root}/deps/zydis"
tmp_a="$(mktemp)"
tmp_b="$(mktemp)"
set +e
(
  cd /tmp
  bash "${root}/scripts/lib/ensure-submodules.sh"
) >"${tmp_a}" 2>&1 &
pid_a=$!
(
  cd /
  bash "${root}/scripts/lib/ensure-submodules.sh"
) >"${tmp_b}" 2>&1 &
pid_b=$!
wait "${pid_a}"
status_a=$?
wait "${pid_b}"
status_b=$?
set -e
if [[ "${status_a}" -eq 0 && "${status_b}" -eq 0 ]] \
  && [[ -f "${root}/deps/zydis/CMakeLists.txt" ]] \
  && ! grep -Eiq 'unable to create|index\.lock|Unable to create|another git process' "${tmp_a}" "${tmp_b}"; then
  ok "two concurrent ensure-submodules.sh callers both exit 0"
else
  echo "----- concurrent caller A (exit ${status_a}) -----" >&2
  cat "${tmp_a}" >&2 || true
  echo "----- concurrent caller B (exit ${status_b}) -----" >&2
  cat "${tmp_b}" >&2 || true
  die "concurrent submodule ensure failed or left Zydis unchecked out"
fi
rm -f "${tmp_a}" "${tmp_b}"

echo "== 3) Real cross-compile configure + cmake --install =="
cmake -S "${root}" -B "${build_dir}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE="${root}/cmake/mingw-w64-x86_64.cmake" \
  -DCMAKE_INSTALL_PREFIX="${install_prefix}"
system_cmake="$(echo "${build_dir}"/CMakeFiles/*/CMakeSystem.cmake)"
cross="$(sed -n 's/^set(CMAKE_CROSSCOMPILING "\([^"]*\)").*/\1/p' "${system_cmake}" | head -1)"
if [[ "${cross}" == "TRUE" ]] \
  && grep -q 'set(CMAKE_SYSTEM_NAME "Windows")' "${system_cmake}" \
  && grep -q 'set(CMAKE_HOST_SYSTEM_NAME "Linux")' "${system_cmake}"; then
  ok "CMAKE_CROSSCOMPILING remains TRUE for the MinGW Windows toolchain"
else
  die "expected Linux-hosted Windows cross compile with CMAKE_CROSSCOMPILING=TRUE, got '${cross}'"
fi
if grep -Eq 'CMAKE_CROSSCOMPILING.*(OFF|FALSE|FORCE)' "${root}/cmake/mingw-w64-x86_64.cmake"; then
  die "toolchain still forces CMAKE_CROSSCOMPILING off"
else
  ok "toolchain file does not force CMAKE_CROSSCOMPILING off"
fi

if grep -R "RUNTIME_DEPENDENCIES" "${build_dir}/cmake_install.cmake" >/dev/null 2>&1; then
  die "cmake_install.cmake still contains RUNTIME_DEPENDENCIES under cross compile"
else
  ok "cross-compile install rule omits RUNTIME_DEPENDENCIES"
fi

cmake --build "${build_dir}" --parallel
# --prefix overrides the project’s set(CMAKE_INSTALL_PREFIX ...) so the test
# can assert the install path without editing host-install layout.
cmake --install "${build_dir}" --prefix "${install_prefix}"
installed_exe="${install_prefix}/bin/win11-toggle-rounded-corners.exe"
if [[ -f "${installed_exe}" ]] && file "${installed_exe}" | grep -q 'PE32+ executable'; then
  ok "cmake --install places the PE executable without host runtime scanning"
else
  die "cmake --install did not produce ${installed_exe}"
fi

echo "== 4) Wine smoke (minimal product action) =="
export WINEDEBUG=-all
set +e
wine_help="$(wine "${installed_exe}" --help 2>&1)"
help_exit=$?
wine_disable="$(wine "${installed_exe}" --disable 2>&1)"
disable_exit=$?
set -e
if echo "${wine_help}" | grep -q 'Win11 Toggle Rounded Corners v1.4' \
  && echo "${wine_help}" | grep -q -- '--daemon' \
  && [[ "${help_exit}" -eq 0 ]]; then
  ok "Wine --help prints v1.4 banner with --daemon and exits 0"
else
  echo "${wine_help}" >&2
  die "Wine --help smoke failed (exit ${help_exit})"
fi
if echo "${wine_disable}" | grep -q 'Failed to find dwm process' \
  && [[ "${disable_exit}" -eq 1 ]]; then
  ok "Wine --disable exits 1 with the expected DWM-missing message"
else
  echo "${wine_disable}" >&2
  die "Wine --disable smoke failed (exit ${disable_exit})"
fi

echo "== 5) CMAKE_INSTALL_PREFIX respects -D =="
prefix_probe="${root}/output/mingw-prefix-probe"
rm -rf "${build_dir}" "${prefix_probe}"
cmake -S "${root}" -B "${build_dir}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE="${root}/cmake/mingw-w64-x86_64.cmake" \
  -DCMAKE_INSTALL_PREFIX="${prefix_probe}"
cached_prefix="$(awk -F= '/^CMAKE_INSTALL_PREFIX:PATH=/{print $2; exit}' "${build_dir}/CMakeCache.txt")"
if [[ "${cached_prefix}" == "${prefix_probe}" ]]; then
  ok "CMAKE_INSTALL_PREFIX from -D is preserved in the cache"
else
  die "expected CMAKE_INSTALL_PREFIX=${prefix_probe}, got '${cached_prefix}'"
fi

echo
echo "Regression summary: ${pass} passed, ${fail} failed"
if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi
