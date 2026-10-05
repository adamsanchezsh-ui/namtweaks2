#Requires -RunAsAdministrator
# namtweaks2 - undo: reverts everything namtweaks2.ps1 changed.

$exe = 'FortniteClient-Win64-Shipping.exe'

function Set-Reg($path, $name, $value) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name $name -Value $value -PropertyType DWord -Force | Out-Null
}

# Balanced power plan
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e

# Game DVR / capture back to Windows defaults
Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 1
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 1

# Remove CPU priority override
$ifeo = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exe"
if (Test-Path "$ifeo\PerfOptions") { Remove-Item "$ifeo\PerfOptions" -Recurse -Force }

Write-Host 'namtweaks2 reverted. Restart Windows.' -ForegroundColor Green
