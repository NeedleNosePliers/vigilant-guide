@echo off
set "F=%~f0"&set "T=%TEMP%\teams_active_%RANDOM%.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try{gc $env:F|select -Skip 4|Set-Content $env:T -Enc UTF8;&$env:T}catch{Write-Host $_ -F Red;Read-Host 'Erreur - appuie sur Entree'}"
del "%T%" 2>nul&exit /b
# ============================================================
#  Teams Active Keeper  —  bouge la souris toutes les 30 s
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
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(int esFlags);
}
"@ -Language CSharp

[Win32]::SetThreadExecutionState(-2147483645) | Out-Null

function Nudge {
    $p = New-Object Win32+POINT
    [Win32]::GetCursorPos([ref]$p) | Out-Null
    [Win32]::SetCursorPos($p.X + $NUDGE_PX, $p.Y) | Out-Null
    Start-Sleep -Milliseconds 150
    [Win32]::SetCursorPos($p.X, $p.Y) | Out-Null
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

[Win32]::SetThreadExecutionState([int]::MinValue) | Out-Null

Read-Host "`nAppuie sur Entree pour fermer"
