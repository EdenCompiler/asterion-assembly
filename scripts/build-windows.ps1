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
# Entradas ZIP usam barras normais também no Windows (APPNOTE), permitindo
# extração sem avisos/falhas com Info-ZIP no Linux e no smoke test Wine.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$ArchivePath = "$Root\dist\asterion-assembly-windows-x64.zip"
$Stream = [System.IO.File]::Open($ArchivePath, [System.IO.FileMode]::Create)
$Archive = [System.IO.Compression.ZipArchive]::new($Stream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $Base = (Split-Path -Parent $Package).Length + 1
    Get-ChildItem -LiteralPath $Package -Recurse -File | Sort-Object FullName | ForEach-Object {
        $Entry = $_.FullName.Substring($Base).Replace('\', '/')
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $Archive, $_.FullName, $Entry, [System.IO.Compression.CompressionLevel]::Optimal)
    }
} finally { $Archive.Dispose(); $Stream.Dispose() }
Write-Host "Criado: $Root\dist\asterion-assembly-windows-x64.zip"
