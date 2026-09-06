#!/usr/bin/env bash
set -euo pipefail
mkdir -p build/player-ui-playtest
save_dir=$(mktemp -d "$PWD/build/player-ui-playtest/run-XXXXXX")
export SDL_AUDIODRIVER=dummy ASTERION_JOURNEY_LIBRARY=1 ASTERION_SAVE_DIR="$save_dir/"
timeout --kill-after=5 180 sbcl --script tests/sdl-player-ui-playtest.lisp >build/player-ui-playtest/game.log 2>&1
grep -q 'SDL PLAYER UI OK' build/player-ui-playtest/game.log
if grep -Eiq 'unhandled|fatal|backtrace|ANTIGONUS ERROR' build/player-ui-playtest/game.log; then exit 1; fi
echo 'Player UI: SDL remapping, profiles and saves OK'
