#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
test_file=${1:-tests/smoke.scd}

if [ -n "${SCLANG_BIN:-}" ]; then
    sc_binary=$SCLANG_BIN
elif command -v sclang >/dev/null 2>&1; then
    sc_binary=$(command -v sclang)
elif [ -x /Applications/SuperCollider.app/Contents/MacOS/sclang ]; then
    sc_binary=/Applications/SuperCollider.app/Contents/MacOS/sclang
else
    echo "sclang was not found. Set SCLANG_BIN to its full path." >&2
    exit 1
fi

exec "$sc_binary" "$project_dir/$test_file"
