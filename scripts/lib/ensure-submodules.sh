#!/usr/bin/env bash
# Initialize git submodules from the repository root, even when the caller’s
# working directory is elsewhere. Concurrent callers serialize on a lock file
# under .git so install and build scripts cannot race the same checkout.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

lock_dir="${root}/.git"
if [[ ! -d "${lock_dir}" ]]; then
  echo "error: ${root} is not a git checkout (.git missing)" >&2
  exit 1
fi

lock_file="${lock_dir}/submodule-update.lock"
exec 9>"${lock_file}"
if ! flock -w 120 9; then
  echo "error: timed out waiting for submodule update lock (${lock_file})" >&2
  exit 1
fi

git submodule update --init --recursive
