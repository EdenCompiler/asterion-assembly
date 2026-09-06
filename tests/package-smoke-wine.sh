#!/usr/bin/env bash
set -euo pipefail
raiz="$(cd "$(dirname "$0")/.." && pwd)"
pacote="${1:-$raiz/dist/asterion-assembly-windows-x64.zip}"
saida="$raiz/build/wine-smoke"
[[ -f "$pacote" ]]
mkdir -p "$saida"
unzip -qo "$pacote" -d "$saida"
# Prefixo exclusivo do teste; nenhum atalho/janela vai para o desktop do usuário.
export WINEPREFIX="$saida/prefix"
export WINEARCH=win64
export WINEDEBUG=-all
export WINEDLLOVERRIDES='winemenubuilder.exe=d'
export SDL_AUDIODRIVER=dummy
cd "$saida/AsterionAssembly-windows-x64"
timeout 60 wine ./asterion-assembly.exe --headless-smoke >headless.log 2>headless.err
timeout 60 wine ./asterion-assembly.exe --render-smoke >render.log 2>render.err
grep -q 'CIRCUIT SMOKE OK' headless.log
grep -q 'CIRCUIT SMOKE OK' render.log
grep -q 'Renderer: opengl; OpenGL:' render.err
[[ "$(identify -format '%m %wx%h' circuit-smoke.ppm)" == 'PPM 1280x720' ]]
if grep -Eiq 'unhandled|fatal|backtrace|ANTIGONUS ERROR|encerrou com erro' headless.log headless.err render.log render.err; then
  exit 1
fi
echo 'Windows ZIP under Wine: native executable, circuits, persistence and OpenGL readback OK'
