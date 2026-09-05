#!/usr/bin/env bash
set -euo pipefail

raiz="$(cd "$(dirname "$0")/.." && pwd)"
saida="$raiz/build/package-smoke"
mkdir -p "$saida"
unzip -qo "$raiz/dist/asterion-assembly-linux-x64.zip" -d "$saida"
cd "$saida/AsterionAssembly-linux-x64"
export SDL_AUDIODRIVER=dummy

timeout 60 ./play.sh --headless-smoke >headless.log 2>&1
timeout 60 ./play.sh --render-smoke >render.log 2>&1
grep -q 'CIRCUIT SMOKE OK' headless.log
grep -q 'CIRCUIT SMOKE OK' render.log
[[ "$(identify -format '%m %wx%h' circuit-smoke.ppm)" == 'PPM 1280x720' ]]
if grep -Eiq 'unhandled|fatal|backtrace|ANTIGONUS ERROR|encerrou com erro' headless.log render.log; then
  exit 1
fi

./play.sh --en >smoke.log 2>&1 &
pid_jogo=$!
janela=""
for tentativa in $(seq 1 80); do
  janela="$(xdotool search --name 'Asterion Assembly' 2>/dev/null | tail -1 || true)"
  [[ -n "$janela" ]] && break
  sleep 0.1
done
[[ -n "$janela" ]]
import -window "$janela" smoke.png
xdotool key --window "$janela" Escape
wait "$pid_jogo"
[[ -s smoke.png ]]
if grep -Eiq 'unhandled|fatal|backtrace|ANTIGONUS ERROR' smoke.log; then
  echo "Falha no pacote Linux" >&2
  exit 1
fi
echo "ZIP Linux extraído e executado com SDL empacotada: smoke test OK"
