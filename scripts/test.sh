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

if [ -n "${SCLANG_ARCH:-}" ]; then
    exec arch "-$SCLANG_ARCH" "$sc_binary" "$project_dir/$test_file"
fi

# Some universal macOS SuperCollider builds ship an arm64 Qt runtime that
# aborts during startup with a missing-NEON error. Prefer the native binary,
# but transparently use its x86_64 slice under Rosetta when only that slice can
# start. Keep this probe macOS/Apple-Silicon-specific so other platforms retain
# their normal launch behavior.
if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
    if ! ("$sc_binary" -v >/dev/null 2>&1) 2>/dev/null \
        && arch -x86_64 "$sc_binary" -v >/dev/null 2>&1; then
        echo "Native arm64 sclang failed its startup probe; using x86_64." >&2
        exec arch -x86_64 "$sc_binary" "$project_dir/$test_file"
    fi
fi

exec "$sc_binary" "$project_dir/$test_file"
