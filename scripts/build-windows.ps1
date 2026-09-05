$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Dist = Join-Path $Root "dist\windows"
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
$env:ASTERION_OUTPUT = Join-Path $Dist "asterion-assembly.exe"
sbcl --script (Join-Path $Root "build.lisp")
if ($LASTEXITCODE -ne 0) {
    throw "A compilação SBCL falhou com o código $LASTEXITCODE."
}
$Package = Join-Path $Root "dist\AsterionAssembly-windows-x64"
Remove-Item -Recurse -Force $Package -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "$Package\mods", "$Package\docs" | Out-Null
Copy-Item "$Dist\asterion-assembly.exe" $Package
Copy-Item "$Root\LICENSE", "$Root\THIRD_PARTY.md", "$Root\README.md" $Package
Copy-Item -Recurse "$Root\assets" $Package
Copy-Item -Recurse "$Root\mods\example-more-belts" "$Package\mods"
Copy-Item "$Root\docs\MANUAL.md", "$Root\docs\MODDING.md", "$Root\docs\API.md", "$Root\docs\UPGRADE-3.md" "$Package\docs"
if ($env:SDL_BIN) { Copy-Item "$env:SDL_BIN\*.dll" $Package }
Compress-Archive -Force -Path $Package -DestinationPath "$Root\dist\asterion-assembly-windows-x64.zip"
Write-Host "Criado: $Root\dist\asterion-assembly-windows-x64.zip"
