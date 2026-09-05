#!/usr/bin/env bash
set -euo pipefail
raiz="$(cd "$(dirname "$0")/.." && pwd)"
# Tons originais determinísticos, sem ruído aleatório ou recursos externos.
ffmpeg -loglevel error -y -f lavfi -i 'sine=frequency=660:duration=0.35' \
  -af 'afade=t=in:d=0.02,afade=t=out:st=0.20:d=0.15,volume=0.24' \
  -ar 44100 -ac 2 "$raiz/assets/audio/alarm-warning.wav"
ffmpeg -loglevel error -y -f lavfi -i 'sine=frequency=990:duration=0.6' \
  -af 'tremolo=f=8:d=0.8,afade=t=in:d=0.02,afade=t=out:st=0.45:d=0.15,volume=0.24' \
  -ar 44100 -ac 2 "$raiz/assets/audio/alarm-critical.wav"
