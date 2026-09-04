#!/usr/bin/env bash
set -euo pipefail

raiz="$(cd "$(dirname "$0")/.." && pwd)"
saida="$raiz/build/menu-playtest"
mkdir -p "$saida"
find "$saida" -maxdepth 1 -type f -delete
export SDL_AUDIODRIVER=dummy

cd "$raiz"
sbcl --script run.lisp en 1701 >"$saida/game.log" 2>&1 &
pid_jogo=$!
encerrar() {
  if kill -0 "$pid_jogo" 2>/dev/null; then
    kill "$pid_jogo" 2>/dev/null || true
    wait "$pid_jogo" 2>/dev/null || true
  fi
}
trap encerrar EXIT

janela=""
for tentativa in $(seq 1 80); do
  janela="$(xdotool search --name 'Asterion Assembly' 2>/dev/null | tail -1 || true)"
  [[ -n "$janela" ]] && break
  sleep 0.1
done
[[ -n "$janela" ]]
sleep 0.5
import -window "$janela" "$saida/01-main-menu.png"

xdotool key --window "$janela" Down Down Return
sleep 0.3
import -window "$janela" "$saida/02-settings.png"
xdotool key --window "$janela" Right Down Right Down Right
sleep 0.2
import -window "$janela" "$saida/03-settings-changed.png"
xdotool key --window "$janela" Escape

xdotool key --window "$janela" Down Down Down Return
sleep 0.3
import -window "$janela" "$saida/04-mods.png"
xdotool key --window "$janela" Escape Down Down Down Down Return
sleep 0.3
import -window "$janela" "$saida/05-credits.png"
xdotool key --window "$janela" Escape Return
sleep 0.6
import -window "$janela" "$saida/06-gameplay.png"

xdotool key --window "$janela" Escape
sleep 0.3
import -window "$janela" "$saida/07-pause-menu.png"
xdotool key --window "$janela" Down Down Down Return
sleep 0.4
import -window "$janela" "$saida/08-back-to-menu.png"

xdotool keydown --window "$janela" Escape 2>/dev/null || true
xdotool keyup --window "$janela" Escape 2>/dev/null || true
for tentativa in $(seq 1 30); do
  kill -0 "$pid_jogo" 2>/dev/null || break
  sleep 0.1
done
if kill -0 "$pid_jogo" 2>/dev/null; then encerrar; else wait "$pid_jogo"; fi
trap - EXIT

if grep -Eiq 'unhandled|fatal|backtrace|ANTIGONUS ERROR' "$saida/game.log"; then
  echo "Falha detectada no frontend" >&2
  exit 1
fi
quantidade="$(find "$saida" -maxdepth 1 -name '*.png' | wc -l)"
[[ "$quantidade" -eq 8 ]]
echo "Frontend virtual concluído: $quantidade telas, log limpo."
