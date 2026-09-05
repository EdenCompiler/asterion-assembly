#!/usr/bin/env bash
set -euo pipefail
mkdir -p build/circuit-playtest
export SDL_AUDIODRIVER=dummy
sbcl --script tests/circuit-scene.lisp >build/circuit-playtest/game.log 2>&1 &
game_pid=$!
trap 'kill "$game_pid" 2>/dev/null || true' EXIT
window=""
for attempt in $(seq 1 80); do
  window=$(xdotool search --name 'circuit playtest' 2>/dev/null | tail -1 || true)
  [[ -n "$window" ]] && break
  sleep 0.1
done
[[ -n "$window" ]]
sleep 1
xdotool key --window "$window" c
# Centro da câmera: personagem (0.5, 1.5). Portas do combinador em 0.18/0.82.
xdotool mousemove --window "$window" 448 296 click 1
xdotool mousemove --window "$window" 534 296 click 1
xdotool mousemove --window "$window" 554 296 mousedown 1
xdotool mousemove --window "$window" 640 296 mouseup 1
sleep 0.4
import -window "$window" build/circuit-playtest/red-connected.png
xdotool key --window "$window" x
xdotool mousemove --window "$window" 448 296 click 1
xdotool mousemove --window "$window" 640 296 click 1
sleep 0.2
import -window "$window" build/circuit-playtest/green-connected.png
xdotool mousemove --window "$window" 640 296 click 3
xdotool mousemove --window "$window" 980 135 click 1
sleep 0.2
import -window "$window" build/circuit-playtest/accessible-palette.png
xdotool key --window "$window" Tab
xdotool mousemove --window "$window" 1180 245 click 1
xdotool mousemove --window "$window" 1180 287 click --repeat 2 --delay 120 1
sleep 0.2
import -window "$window" build/circuit-playtest/lamp-controls.png
xdotool windowsize "$window" 1024 640
sleep 0.3
import -window "$window" build/circuit-playtest/1024x640.png
xdotool key --window "$window" c Escape Down Down Down Down Return
for attempt in $(seq 1 50); do
  kill -0 "$game_pid" 2>/dev/null || break
  sleep 0.1
done
if kill -0 "$game_pid" 2>/dev/null; then exit 1; fi
wait "$game_pid"
trap - EXIT
grep -q 'CIRCUIT INPUT OK' build/circuit-playtest/game.log
if grep -Eiq 'unhandled|fatal|backtrace|ANTIGONUS ERROR' build/circuit-playtest/game.log; then exit 1; fi
echo 'Circuit mouse playtest: connections, drag, refund, palette, lamp controls and rendering OK'
