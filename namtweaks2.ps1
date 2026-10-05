#Requires -RunAsAdministrator
<#
  namtweaks2 - free, open-source safe Fortnite tweaks for Windows 10/11
  Original script. Creates a restore point first. Undo with undo.ps1.
#>

$ErrorActionPreference = 'Continue'
$exe = 'FortniteClient-Win64-Shipping.exe'

function Set-Reg($path, $name, $value, $type = 'DWord') {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name $name -Value $value -PropertyType $type -Force | Out-Null
}

Write-Host '[1/5] Creating restore point...' -ForegroundColor Cyan
try {
    Enable-ComputerRestore -Drive "$env:SystemDrive\"
    Checkpoint-Computer -Description 'namtweaks2' -RestorePointType MODIFY_SETTINGS
} catch { Write-Warning "Restore point skipped: $($_.Exception.Message)" }

Write-Host '[2/5] High Performance power plan...' -ForegroundColor Cyan
$hp = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
if (-not (powercfg /list | Select-String $hp)) { powercfg -duplicatescheme $hp | Out-Null }
powercfg /setactive $hp

Write-Host '[3/5] Disabling Xbox Game Bar / background recording...' -ForegroundColor Cyan
Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0

Write-Host '[4/5] Enabling Windows Game Mode...' -ForegroundColor Cyan
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1

Write-Host '[5/5] High CPU priority for Fortnite...' -ForegroundColor Cyan
$ifeo = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exe\PerfOptions"
Set-Reg $ifeo 'CpuPriorityClass' 3   # 3 = High

Write-Host 'Done. Restart Windows. Use undo.ps1 to revert.' -ForegroundColor Green
