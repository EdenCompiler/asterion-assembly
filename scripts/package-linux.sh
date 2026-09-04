#!/usr/bin/env bash
set -euo pipefail
raiz="$(cd "$(dirname "$0")/.." && pwd)"
pacote="$raiz/dist/AsterionAssembly-linux-x64"
rm -rf "$pacote"
mkdir -p "$pacote/mods" "$pacote/docs"
bash "$raiz/scripts/generate-audio.sh"
bash "$raiz/scripts/generate-store-png.sh"
cp "$raiz/dist/linux/asterion-assembly" "$pacote/"
cp "$raiz/LICENSE" "$raiz/THIRD_PARTY.md" "$raiz/README.md" "$pacote/"
cp -r "$raiz/assets" "$pacote/"
cp -r "$raiz/mods/example-more-belts" "$pacote/mods/"
cp "$raiz/docs/MANUAL.md" "$raiz/docs/MODDING.md" "$pacote/docs/"
printf '#!/usr/bin/env bash\ncd "$(dirname "$0")"\nexec ./asterion-assembly "$@"\n' > "$pacote/play.sh"
chmod +x "$pacote/play.sh" "$pacote/asterion-assembly"
mkdir -p "$pacote/lib"
for biblioteca in libSDL2-2.0.so.0 libSDL2_image-2.0.so.0 libSDL2_mixer-2.0.so.0; do
  caminho=""
  for candidato in "/usr/lib/x86_64-linux-gnu/$biblioteca" "/lib/x86_64-linux-gnu/$biblioteca" "/usr/lib64/$biblioteca"; do
    if [[ -f "$candidato" ]]; then caminho="$candidato"; break; fi
  done
  if [[ -n "$caminho" ]]; then cp -L "$caminho" "$pacote/lib/"; fi
done
(exportador='export LD_LIBRARY_PATH="$PWD/lib:${LD_LIBRARY_PATH:-}"'; sed -i "3i$exportador" "$pacote/play.sh")
(cd "$raiz/dist" && zip -qr asterion-assembly-linux-x64.zip AsterionAssembly-linux-x64)
echo "Criado: $raiz/dist/asterion-assembly-linux-x64.zip"
