#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$root/assets/audio"
ffmpeg -loglevel error -y -f lavfi -i "sine=frequency=740:duration=0.09" -af "afade=t=out:st=0.04:d=0.05,volume=0.22" -ar 44100 -ac 2 "$root/assets/audio/build.wav"
ffmpeg -loglevel error -y -f lavfi -i "sine=frequency=240:duration=0.12" -af "afade=t=out:st=0.04:d=0.08,volume=0.18" -ar 44100 -ac 2 "$root/assets/audio/remove.wav"
ffmpeg -loglevel error -y -f lavfi -i "sine=frequency=1180:duration=0.10" -af "afade=t=out:st=0.02:d=0.08,volume=0.16" -ar 44100 -ac 2 "$root/assets/audio/shoot.wav"
ffmpeg -loglevel error -y -f lavfi -i "anoisesrc=color=brown:duration=0.12" -af "lowpass=f=900,afade=t=out:st=0.03:d=0.09,volume=0.12" -ar 44100 -ac 2 "$root/assets/audio/impact.wav"
echo "Áudio procedural gerado em assets/audio"
