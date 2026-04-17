# Setup.ps1 — a lancer UNE SEULE FOIS en tant qu'Administrateur
# Cree un certificat auto-signe, l'installe comme editeur de confiance,
# et signe TeamsActive.ps1. Apres ca, double-clic sans aucun avertissement.

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$target     = Join-Path $scriptDir "TeamsActive.ps1"
$certName   = "TeamsActive Local Signing"

Write-Host "`n=== Setup TeamsActive ===" -ForegroundColor Yellow

# 1. Creer le certificat s'il n'existe pas deja
$cert = Get-ChildItem Cert:\LocalMachine\My |
        Where-Object { $_.Subject -eq "CN=$certName" } |
        Select-Object -First 1

if (-not $cert) {
    Write-Host "Creation du certificat..." -ForegroundColor Cyan
    $cert = New-SelfSignedCertificate `
        -Subject        "CN=$certName" `
        -CertStoreLocation "Cert:\LocalMachine\My" `
        -KeyUsage       DigitalSignature `
        -Type           CodeSigningCert `
        -NotAfter       (Get-Date).AddYears(10)
    Write-Host "  Certificat cree : $($cert.Thumbprint)" -ForegroundColor Green
} else {
    Write-Host "  Certificat existant : $($cert.Thumbprint)" -ForegroundColor Green
}

# 2. Installer dans TrustedPublisher et Root (requis pour AllSigned)
foreach ($store in @("TrustedPublisher", "Root")) {
    $s = [System.Security.Cryptography.X509Certificates.X509Store]::new(
            $store, "LocalMachine")
    $s.Open("ReadWrite")
    if (-not ($s.Certificates | Where-Object Thumbprint -eq $cert.Thumbprint)) {
        $s.Add($cert)
        Write-Host "  Installe dans $store" -ForegroundColor Green
    }
    $s.Close()
}

# 3. Signer TeamsActive.ps1
Write-Host "Signature de $target..." -ForegroundColor Cyan
$result = Set-AuthenticodeSignature -FilePath $target -Certificate $cert `
          -TimestampServer "http://timestamp.digicert.com" -ErrorAction SilentlyContinue

if (-not $result -or $result.Status -notin @("Valid","UnknownError")) {
    # Retry sans timestamp (pas besoin d'internet)
    $result = Set-AuthenticodeSignature -FilePath $target -Certificate $cert
}

if ($result.Status -eq "Valid") {
    Write-Host "  Signe avec succes !" -ForegroundColor Green
} else {
    Write-Host "  Statut signature : $($result.Status)" -ForegroundColor Yellow
}

# 4. Mettre la politique a AllSigned pour que le double-clic fonctionne
$current = Get-ExecutionPolicy -Scope LocalMachine
if ($current -notin @("AllSigned","Unrestricted","Bypass")) {
    Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy AllSigned -Force
    Write-Host "  ExecutionPolicy -> AllSigned" -ForegroundColor Green
}

Write-Host "`nSetup termine. Tu peux maintenant double-cliquer sur TeamsActive.ps1" -ForegroundColor Yellow
Write-Host "(clic-droit > Ouvrir avec > Windows PowerShell)" -ForegroundColor Yellow
Read-Host "`nAppuie sur Entree pour fermer"
