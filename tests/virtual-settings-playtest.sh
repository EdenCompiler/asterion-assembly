#!/usr/bin/env bash
set -euo pipefail
mkdir -p build/settings-playtest
export SDL_AUDIODRIVER=dummy
export ASTERION_SAVE_DIR="$PWD/build/settings-playtest/saves/"
# Fullscreen desktop depende do protocolo do gerenciador de janelas X11.
# Isola também configurações/cache do WM; nenhuma janela usa o display do usuário.
mkdir -p build/settings-playtest/wm-config build/settings-playtest/wm-cache
XDG_CONFIG_HOME="$PWD/build/settings-playtest/wm-config" \
  "${ASTERION_TEST_WM:-openbox}" >build/settings-playtest/wm.log 2>&1 &
wm_pid=$!
trap 'kill "$wm_pid" 2>/dev/null || true' EXIT
sleep 1
sbcl --script tests/settings-scene.lisp >build/settings-playtest/game.log 2>&1 &
game_pid=$!
trap 'kill "$game_pid" "$wm_pid" 2>/dev/null || true' EXIT
window=""
for attempt in $(seq 1 100); do
  window=$(xdotool search --name 'Asterion settings playtest' 2>/dev/null | tail -1 || true)
  [[ -n "$window" ]] && break
  sleep 0.1
done
[[ -n "$window" ]]
for attempt in $(seq 1 100); do
  grep -q 'SETTINGS READY' build/settings-playtest/game.log && break
  sleep 0.1
done
grep -q 'SETTINGS READY' build/settings-playtest/game.log
xdotool mousemove --window "$window" 160 489 click 1
sleep 0.3
import -window "$window" build/settings-playtest/1600x900.png
[[ "$(identify -format '%wx%h' build/settings-playtest/1600x900.png)" == '1600x900' ]]
xdotool mousemove --window "$window" 200 685 click 1
sleep 0.3
import -window "$window" build/settings-playtest/fullscreen.png
[[ "$(identify -format '%wx%h' build/settings-playtest/fullscreen.png)" == '1920x1080' ]]
xdotool mousemove --window "$window" 240 907 click 1
sleep 0.3
# Canvas lógico 1422×800: SDL converte as posições físicas do mouse.
xdotool mousemove --window "$window" 880 425 click 1
xdotool mousemove --window "$window" 880 580 click 1
xdotool mousemove --window "$window" 880 657 click 1
sleep 0.2
import -window "$window" build/settings-playtest/ui-90-colorblind.png
xdotool key --window "$window" Escape Escape
for attempt in $(seq 1 50); do
  kill -0 "$game_pid" 2>/dev/null || break
  sleep 0.1
done
if kill -0 "$game_pid" 2>/dev/null; then exit 1; fi
wait "$game_pid"
kill "$wm_pid" 2>/dev/null || true
trap - EXIT
grep -q 'SETTINGS INPUT OK' build/settings-playtest/game.log
if grep -Eiq 'unhandled|fatal|backtrace|ANTIGONUS ERROR' build/settings-playtest/game.log; then exit 1; fi
echo 'Settings SDL playtest: resolution, fullscreen, UI scale, audio, palette and profile OK'
