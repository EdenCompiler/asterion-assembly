#!/usr/bin/env bash
set -euo pipefail
input_mode=${1:-mouse}
case "$input_mode" in mouse|gamepad) ;; *) echo 'Expected mouse or gamepad' >&2; exit 2 ;; esac
output_dir="$PWD/build/first-hour-$input_mode"
mkdir -p "$output_dir"
save_dir=$(mktemp -d "$output_dir/run-XXXXXX")
export SDL_AUDIODRIVER=dummy ASTERION_TEST_INPUT="$input_mode" ASTERION_SAVE_DIR="$save_dir/"
export ASTERION_TEST_OUTPUT="$save_dir/"
unset ASTERION_JOURNEY_LIBRARY
timeout --kill-after=5 1800 sbcl --script tests/first-hour-playtest.lisp >"$output_dir/game.log" 2>&1
cp "$output_dir/game.log" "$save_dir/game.log"
grep -q 'FIRST HOUR INPUT JOURNEY OK' "$output_dir/game.log"
if grep -Eiq 'unhandled|fatal|backtrace|ANTIGONUS ERROR' "$output_dir/game.log"; then exit 1; fi
echo "First-hour SDL journey: $input_mode OK; evidence in $output_dir"
