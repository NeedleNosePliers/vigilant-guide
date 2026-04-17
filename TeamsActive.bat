@echo off
set "F=%~f0"&set "T=%TEMP%\teams_active_%RANDOM%.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try{gc $env:F|select -Skip 4|Set-Content $env:T -Enc UTF8;&$env:T}catch{Write-Host $_ -F Red;Read-Host 'Erreur - appuie sur Entree'}"
del "%T%" 2>nul&exit /b
# ============================================================
#  Teams Active Keeper  —  bouge la souris toutes les 20 s
#  Appuie sur Q pour arreter proprement.
#  Ferme la fenetre pour forcer l'arret.
# ============================================================

$INTERVAL_SEC = 20
$NUDGE_PX     = 200

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);

    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT {
        public int dx, dy;
        public uint mouseData, dwFlags, time;
        public IntPtr dwExtraInfo;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT {
        public uint type;
        public MOUSEINPUT mi;
    }
    [DllImport("user32.dll")] public static extern uint SendInput(uint n, INPUT[] inp, int sz);
}
"@ -Language CSharp

function Nudge {
    $p = New-Object Win32+POINT
    [Win32]::GetCursorPos([ref]$p) | Out-Null

    $move = New-Object Win32+INPUT
    $move.type = 0
    $move.mi.dwFlags = 0x0001
    $move.mi.dx = $NUDGE_PX
    [Win32]::SendInput(1, @($move), [System.Runtime.InteropServices.Marshal]::SizeOf($move)) | Out-Null
    Start-Sleep -Milliseconds 150
    $move.mi.dx = -$NUDGE_PX
    [Win32]::SendInput(1, @($move), [System.Runtime.InteropServices.Marshal]::SizeOf($move)) | Out-Null

    Write-Host ("[{0}]  nudge @ ({1}, {2})" -f (Get-Date -Format "HH:mm:ss"), $p.X, $p.Y) -ForegroundColor Cyan
}

Clear-Host
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "  Teams Active Keeper" -ForegroundColor Yellow
Write-Host "  Nudge toutes les $INTERVAL_SEC secondes" -ForegroundColor Yellow
Write-Host "  Appuie sur  Q  pour arreter" -ForegroundColor Yellow
Write-Host "============================================`n" -ForegroundColor Yellow

$running = $true
while ($running) {
    Nudge
    $elapsed = 0.0
    while ($elapsed -lt $INTERVAL_SEC) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq [ConsoleKey]::Q) {
                Write-Host "`nArret." -ForegroundColor Red
                $running = $false
                break
            }
        }
        Start-Sleep -Milliseconds 200
        $elapsed += 0.2
    }
}

Read-Host "`nAppuie sur Entree pour fermer"
