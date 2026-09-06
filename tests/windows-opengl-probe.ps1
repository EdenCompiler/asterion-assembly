# Diagnóstico independente de Lisp para distinguir falha do driver do runtime.
param([switch]$Child)
$ErrorActionPreference = 'Stop'
if ($Child) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class OpenGLProbe {
    [DllImport("SDL2.dll", CallingConvention=CallingConvention.Cdecl)] static extern int SDL_Init(uint flags);
    [DllImport("SDL2.dll", CallingConvention=CallingConvention.Cdecl)] static extern int SDL_GL_SetAttribute(int attr, int value);
    [DllImport("SDL2.dll", CallingConvention=CallingConvention.Cdecl)] static extern IntPtr SDL_CreateWindow(string title, int x, int y, int w, int h, uint flags);
    [DllImport("SDL2.dll", CallingConvention=CallingConvention.Cdecl)] static extern IntPtr SDL_GL_CreateContext(IntPtr window);
    [DllImport("SDL2.dll", CallingConvention=CallingConvention.Cdecl)] static extern void SDL_GL_DeleteContext(IntPtr context);
    [DllImport("SDL2.dll", CallingConvention=CallingConvention.Cdecl)] static extern IntPtr SDL_CreateRenderer(IntPtr window, int index, uint flags);
    [DllImport("SDL2.dll", CallingConvention=CallingConvention.Cdecl)] static extern int SDL_SetHint(string name, string value);
    [DllImport("SDL2.dll", CallingConvention=CallingConvention.Cdecl)] static extern IntPtr SDL_GetError();
    [DllImport("SDL2.dll", CallingConvention=CallingConvention.Cdecl)] static extern void SDL_Quit();
    public static void Run() {
        Console.WriteLine("PROBE SDL_Init: " + SDL_Init(32));
        SDL_GL_SetAttribute(17, 3); SDL_GL_SetAttribute(18, 3); SDL_GL_SetAttribute(21, 2);
        var window = SDL_CreateWindow("OpenGL CI probe", 0, 0, 320, 240, 6);
        Console.WriteLine("PROBE window: " + window);
        var context = SDL_GL_CreateContext(window);
        Console.WriteLine("PROBE context: " + context + "; error: " + Marshal.PtrToStringAnsi(SDL_GetError()));
        SDL_GL_DeleteContext(context);
        SDL_SetHint("SDL_RENDER_DRIVER", "opengl");
        Console.WriteLine("PROBE renderer with window recreation");
        var renderer = SDL_CreateRenderer(window, -1, 6);
        Console.WriteLine("PROBE renderer: " + renderer + "; error: " + Marshal.PtrToStringAnsi(SDL_GetError()));
        SDL_Quit();
        if (context == IntPtr.Zero) throw new Exception("Native OpenGL context unavailable");
    }
}
'@
    [OpenGLProbe]::Run()
    exit
}
$Process = [System.Diagnostics.Process]::new()
$Process.StartInfo.FileName = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$Process.StartInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Child"
$Process.StartInfo.WorkingDirectory = (Get-Location).Path
$Process.StartInfo.EnvironmentVariables['PATH'] = "$env:ASTERION_CI_OPENGL_DIR;$env:SystemRoot\System32;$env:SystemRoot"
$Process.StartInfo.EnvironmentVariables['SDL_OPENGL_LIBRARY'] = Join-Path $env:ASTERION_CI_OPENGL_DIR 'opengl32.dll'
$Process.StartInfo.EnvironmentVariables['GALLIUM_DRIVER'] = 'llvmpipe'
$Process.StartInfo.UseShellExecute = $false
$Process.StartInfo.CreateNoWindow = $true
$Process.StartInfo.RedirectStandardOutput = $true
$Process.StartInfo.RedirectStandardError = $true
try {
    [void]$Process.Start()
    $Out = $Process.StandardOutput.ReadToEndAsync()
    $Err = $Process.StandardError.ReadToEndAsync()
    if (!$Process.WaitForExit(30000)) { $Process.Kill(); $Process.WaitForExit(); Write-Host 'PROBE TIMEOUT' }
    Write-Host $Out.GetAwaiter().GetResult()
    Write-Host $Err.GetAwaiter().GetResult()
} finally { $Process.Dispose() }
