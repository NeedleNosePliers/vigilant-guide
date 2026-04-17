<# :
@echo off
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~f0" %*
exit /b %ERRORLEVEL%
#>
# ============================================================
#  Teams Active Keeper
#  Bouge la souris toutes les 60 secondes pour rester "actif".
#  Double-clic pour lancer — aucune installation requise.
#
#  Appuie sur  Q  pour arrêter proprement.
#  Ferme la fenêtre pour forcer l'arrêt.
# ============================================================

$INTERVAL_SEC = 60   # secondes entre chaque nudge
$NUDGE_PX     = 5    # pixels aller-retour

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }

    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT p);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);
}
"@ -Language CSharp

function Nudge {
    $p = New-Object Win32+POINT
    [Win32]::GetCursorPos([ref]$p) | Out-Null
    [Win32]::SetCursorPos($p.X + $NUDGE_PX, $p.Y) | Out-Null
    Start-Sleep -Milliseconds 150
    [Win32]::SetCursorPos($p.X, $p.Y) | Out-Null
    Write-Host ("[{0}]  nudge @ ({1}, {2})" -f `
        (Get-Date -Format "HH:mm:ss"), $p.X, $p.Y) -ForegroundColor Cyan
}

Clear-Host
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "  Teams Active Keeper" -ForegroundColor Yellow
Write-Host "  Nudge toutes les $INTERVAL_SEC secondes" -ForegroundColor Yellow
Write-Host "  Appuie sur  Q  pour arreter" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow
Write-Host ""

$running = $true
while ($running) {
    Nudge

    $elapsed = 0
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
