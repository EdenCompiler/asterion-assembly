#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$root/assets/store/png"
shopt -s nullglob
sources=("$root/assets/icon.svg" "$root/assets/logo.svg"
         "$root/assets/store/cover.svg" "$root/assets/store"/screenshot-*.svg)
for source in "${sources[@]}"; do
  [[ -f "$source" ]] || continue
  name="$(basename "${source%.svg}")"
  rsvg-convert "$source" -o "$root/assets/store/png/$name.png"
done
echo "Arte comercial PNG gerada em assets/store/png"
