# ==============================================================================
# CREE'S ANTI-BLOAT & SYSTEM RECLAIMER FOR WINDOWS
# Run this in an Administrator PowerShell window.
# ==============================================================================

# Ensure admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator."
    Exit
}

Write-Host "[-] Reclaiming your hardware from corporate bloat..." -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. STRIP TELEMETRY & CORPORATE TRACKING
# ------------------------------------------------------------------------------
Write-Host "[*] Disabling diagnostic tracking and telemetry..." -ForegroundColor Yellow

# Stop and disable diagnostic services
$Services = @("DiagTrack", "dmwappushservice", "WerSvc")
foreach ($Service in $Services) {
    if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
        Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $Service -StartupType Disabled
    }
}

# Registry tweaks to kill telemetry paths
$RegistryPaths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
)
foreach ($Path in $RegistryPaths) {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name "AllowTelemetry" -Value 0 -PropertyType DWord -Force | Out-Null
}

# ------------------------------------------------------------------------------
# 2. PURGE SPONSORED APP CONSUMER EXPERIENCE (Candy Crush, TikTok, etc.)
# ------------------------------------------------------------------------------
Write-Host "[*] Blocking automatic installation of sponsored junk..." -ForegroundColor Yellow

$SubAuthPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $SubAuthPath)) { New-Item -Path $SubAuthPath -Force | Out-Null }
New-ItemProperty -Path $SubAuthPath -Name "SilentInstalledAppsEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $SubAuthPath -Name "ContentDeliveryAllowed" -Value 0 -PropertyType DWord -Force | Out-Null

# ------------------------------------------------------------------------------
# 3. UNINSTALL PROVISIONED OEM & BLOATWARE PACKAGES
# ------------------------------------------------------------------------------
Write-Host "[*] Removing pre-installed app packages..." -ForegroundColor Yellow

$BloatList = @(
    "*Microsoft365Discovery*",
    "*XboxApp*",
    "*XboxGameOverlay*",
    "*GetHelp*",
    "*YourPhone*",
    "*WindowsFeedbackHub*",
    "*BingNews*",
    "*BingWeather*",
    "*SkypeApp*",
    "*ZuneVideo*",
    "*ZuneMusic*"
)

foreach ($App in $BloatList) {
    Get-AppxPackage -Name $App -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object {$_.PackageName -like $App} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------------------------
# 4. CLEAN UP VISUAL EFFECTS & BACKGROUND BACKGROUNDS FOR PERFORMANCE
# ------------------------------------------------------------------------------
Write-Host "[*] Disabling startup delay and background resource hogs..." -ForegroundColor Yellow

# Disable startup delay for snappy folder opening
$SerializePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
if (-not (Test-Path $SerializePath)) { New-Item -Path $SerializePath -Force | Out-Null }
New-ItemProperty -Path $SerializePath -Name "StartupDelayInMSec" -Value 0 -PropertyType DWord -Force | Out-Null

# ------------------------------------------------------------------------------
# FINISH
# ------------------------------------------------------------------------------
Write-Host "[+] Script complete. Your hardware belongs to you again." -ForegroundColor Green
Write-Host "[!] Restart your PC to commit all changes safely." -ForegroundColor Cyan
