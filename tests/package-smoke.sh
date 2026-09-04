#!/usr/bin/env bash
set -euo pipefail

raiz="$(cd "$(dirname "$0")/.." && pwd)"
saida="$raiz/build/package-smoke"
mkdir -p "$saida"
unzip -qo "$raiz/dist/asterion-assembly-linux-x64.zip" -d "$saida"
cd "$saida/AsterionAssembly-linux-x64"
export SDL_AUDIODRIVER=dummy

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
