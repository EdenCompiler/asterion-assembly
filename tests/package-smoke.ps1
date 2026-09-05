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
        # Possui o handle desde Start: Start-Process/PassThru pode devolver
        # ExitCode nulo no PowerShell 5 mesmo após WaitForExit.
        $Process = [System.Diagnostics.Process]::new()
        $Process.StartInfo.FileName = Join-Path (Get-Location) 'asterion-assembly.exe'
        $Process.StartInfo.WorkingDirectory = (Get-Location).Path
        $Process.StartInfo.EnvironmentVariables['PATH'] = "$((Get-Location).Path);$env:SystemRoot\System32;$env:SystemRoot"
        if ($Mode -eq '--render-smoke' -and $env:ASTERION_CI_OPENGL_DIR) {
            # Driver de teste do runner, não um backend SDL alternativo nem
            # uma DLL adicionada ao ZIP distribuído ao jogador.
            $Process.StartInfo.EnvironmentVariables['SDL_OPENGL_LIBRARY'] = Join-Path $env:ASTERION_CI_OPENGL_DIR 'opengl32.dll'
            $Process.StartInfo.EnvironmentVariables['PATH'] += ";$env:ASTERION_CI_OPENGL_DIR"
            $Process.StartInfo.EnvironmentVariables['GALLIUM_DRIVER'] = 'llvmpipe'
        }
        $Process.StartInfo.Arguments = $Mode
        $Process.StartInfo.UseShellExecute = $false
        $Process.StartInfo.CreateNoWindow = $true
        $Process.StartInfo.RedirectStandardOutput = $true
        $Process.StartInfo.RedirectStandardError = $true
        try {
            if (!$Process.Start()) { throw "Smoke could not start: $Mode" }
            $OutputTask = $Process.StandardOutput.ReadToEndAsync()
            $ErrorTask = $Process.StandardError.ReadToEndAsync()
            if (!$Process.WaitForExit(60000)) { $Process.Kill(); throw "Smoke timeout: $Mode" }
            $OutputText = $OutputTask.GetAwaiter().GetResult()
            $ErrorText = $ErrorTask.GetAwaiter().GetResult()
            [System.IO.File]::WriteAllText((Join-Path (Get-Location) $Log), $OutputText)
            [System.IO.File]::WriteAllText((Join-Path (Get-Location) "$Log.err"), $ErrorText)
            if ($Process.ExitCode -ne 0) { throw "Smoke exit code $($Process.ExitCode): $ErrorText" }
            $Text = $OutputText + $ErrorText
        } finally { $Process.Dispose() }
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
    if ($Text -notmatch 'Renderer: opengl; OpenGL:') { throw 'OpenGL renderer not confirmed' }
    Write-Host 'Windows ZIP: circuit simulation, persistence and renderer readback OK'
} finally { Pop-Location }
