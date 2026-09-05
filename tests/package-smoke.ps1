# Executa o ZIP Windows extraído, não a imagem de desenvolvimento.
$ErrorActionPreference = 'Stop'
$SmokeDir = Join-Path $PSScriptRoot '..\build\windows-smoke'
Expand-Archive -Force (Join-Path $PSScriptRoot '..\dist\asterion-assembly-windows-x64.zip') $SmokeDir
$GameDir = Join-Path $SmokeDir 'AsterionAssembly-windows-x64'
Push-Location $GameDir
try {
    $env:SDL_AUDIODRIVER = 'dummy'
    foreach ($Mode in @('--headless-smoke', '--render-smoke')) {
        $Log = if ($Mode -eq '--headless-smoke') { 'headless.log' } else { 'render.log' }
        $Process = Start-Process '.\asterion-assembly.exe' -ArgumentList $Mode -PassThru `
            -RedirectStandardOutput $Log -RedirectStandardError "$Log.err"
        if (!$Process.WaitForExit(60000)) { $Process.Kill(); throw "Smoke timeout: $Mode" }
        $Process.Refresh()
        if ($Process.ExitCode -ne 0) { throw "Smoke exit code: $($Process.ExitCode)" }
        $Text = (Get-Content $Log -Raw) + (Get-Content "$Log.err" -Raw)
        if ($Text -notmatch 'CIRCUIT SMOKE OK' -or $Text -match 'unhandled|fatal|backtrace|ANTIGONUS ERROR|encerrou com erro') {
            throw "Smoke log failure: $Text"
        }
    }
    $Bytes = [System.IO.File]::ReadAllBytes((Join-Path (Get-Location) 'circuit-smoke.ppm'))
    $Header = [System.Text.Encoding]::ASCII.GetBytes("P6`n1280 720`n255`n")
    if ($Bytes.Length -ne ($Header.Length + 1280 * 720 * 3)) { throw 'Invalid readback dimensions/size' }
    for ($I = 0; $I -lt $Header.Length; $I++) {
        if ($Bytes[$I] -ne $Header[$I]) { throw 'Invalid PPM signature' }
    }
    # Dimensões corretas sozinhas também aceitariam uma tela vazia.
    $Colors = [System.Collections.Generic.HashSet[int]]::new()
    for ($I = $Header.Length; $I -lt $Bytes.Length; $I += 3 * 97) {
        $Color = ([int]$Bytes[$I] -shl 16) -bor ([int]$Bytes[$I + 1] -shl 8) -bor [int]$Bytes[$I + 2]
        [void]$Colors.Add($Color)
    }
    if ($Colors.Count -lt 16) { throw 'Renderer readback is blank or lacks scene detail' }
    if ((Get-Content 'render.log' -Raw) -notmatch 'OpenGL 3.3') { throw 'OpenGL renderer not confirmed' }
    Write-Host 'Windows ZIP: circuit simulation, persistence and renderer readback OK'
} finally { Pop-Location }
