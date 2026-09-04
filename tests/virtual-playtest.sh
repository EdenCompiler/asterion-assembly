#!/usr/bin/env bash
set -euo pipefail

raiz="$(cd "$(dirname "$0")/.." && pwd)"
saida="$raiz/build/playtest"
mkdir -p "$saida"
find "$saida" -maxdepth 1 -type f -delete
export SDL_AUDIODRIVER=dummy

cd "$raiz"
sbcl --script tests/playtest-scene.lisp >"$saida/game.log" 2>&1 &
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

# Observa diferentes fases da linha funcional e do item real no transportador.
sleep 1
for quadro in 1 2 3 4 5 6; do
  import -window "$janela" "$saida/transit-$quadro.png"
  sleep 0.22
done

# Hover revela estado, conteúdo e fluxo sem abrir uma janela modal.
xdotool mousemove --window "$janela" 548 330
sleep 0.18
import -window "$janela" "$saida/inspector-belt-flow.png"
xdotool mousemove --window "$janela" 510 330
sleep 0.18
import -window "$janela" "$saida/inspector-miner.png"
xdotool mousemove --window "$janela" 704 264
sleep 0.18
import -window "$janela" "$saida/splitter-two-output-flow.png"

# Um único movimento longo deve preencher todos os segmentos e Z desfaz o último.
xdotool mousemove --window "$janela" 700 400
xdotool mousedown --window "$janela" 1
xdotool mousemove --window "$janela" 828 400
xdotool mouseup --window "$janela" 1
sleep 0.25
import -window "$janela" "$saida/drag-build-line.png"
xdotool key --window "$janela" z
sleep 0.18
import -window "$janela" "$saida/undo-last-segment.png"

# Valida visibilidade e rotação nas quatro direções de caminhada.
for entrada in d a w s; do
  xdotool keydown --window "$janela" "$entrada"
  sleep 0.22
  import -window "$janela" "$saida/humanoid-walk-$entrada.png"
  xdotool keyup --window "$janela" "$entrada"
done

# Parado, o personagem deve acompanhar o cursor e continuar visível.
xdotool mousemove --window "$janela" 390 360
sleep 0.16
import -window "$janela" "$saida/humanoid-idle-left.png"
xdotool mousemove --window "$janela" 850 360
sleep 0.16
import -window "$janela" "$saida/humanoid-idle-right.png"
xdotool mousemove --window "$janela" 770 380 click 2
sleep 0.10
import -window "$janela" "$saida/weapon-vfx.png"

# A árvore deve pausar a fábrica e apresentar os 24 nós e dependências.
xdotool key --window "$janela" t
sleep 0.3
import -window "$janela" "$saida/technology-tree.png"
xdotool key --window "$janela" Escape

# Exercita os principais estados de interface sem abrir janela no desktop real.
xdotool key --window "$janela" b
sleep 0.4
import -window "$janela" "$saida/minimap.png"
xdotool key --window "$janela" Tab
sleep 0.4
import -window "$janela" "$saida/statistics.png"
xdotool key --window "$janela" space
sleep 0.3
import -window "$janela" "$saida/paused.png"
xdotool key --window "$janela" space
xdotool mousemove --window "$janela" 700 420 click 4 click 4
sleep 0.3
import -window "$janela" "$saida/zoom.png"

# Redimensionamento não pode recortar HUD, catálogo nem árvore tecnológica.
xdotool windowsize "$janela" 1024 640
sleep 0.35
import -window "$janela" "$saida/resize-1024x640.png"
xdotool key --window "$janela" t
sleep 0.25
import -window "$janela" "$saida/resize-tech-1024x640.png"
xdotool key --window "$janela" Escape
xdotool windowsize "$janela" 960 720
sleep 0.35
import -window "$janela" "$saida/resize-960x720.png"
xdotool windowsize "$janela" 1280 720
sleep 0.2

xdotool key --window "$janela" Escape
sleep 0.2
xdotool key --window "$janela" Down Down Down Down Return
for tentativa in $(seq 1 30); do
  kill -0 "$pid_jogo" 2>/dev/null || break
  sleep 0.1
done
if kill -0 "$pid_jogo" 2>/dev/null; then encerrar; else wait "$pid_jogo"; fi
trap - EXIT

if grep -Eiq 'unhandled|fatal|backtrace|ANTIGONUS ERROR' "$saida/game.log"; then
  echo "Falha detectada no log do playtest" >&2
  exit 1
fi

quantidade="$(find "$saida" -maxdepth 1 -name '*.png' | wc -l)"
[[ "$quantidade" -eq 26 ]]
echo "Playtest virtual concluído: $quantidade capturas, log limpo."
