#Requires -RunAsAdministrator
<#
  namtweaks2 - free, open-source Fortnite / gaming tweaks for Windows 10/11
  Original code. Every registry change is backed up and fully reversible.

  .\namtweaks2.ps1            interactive menu
  .\namtweaks2.ps1 -All       apply everything
  .\namtweaks2.ps1 -Only 1,3  apply selected tweaks
  .\namtweaks2.ps1 -Undo      revert everything
#>
param([switch]$Undo, [switch]$All, [int[]]$Only)

$ErrorActionPreference = 'Continue'
$Dir   = Join-Path $env:ProgramData 'namtweaks2'
$State = Join-Path $Dir 'backup.json'
New-Item $Dir -ItemType Directory -Force | Out-Null

# ---- backup store: remembers the ORIGINAL value of everything we touch ----
$backup = @{}
if (Test-Path $State) {
    $old = Get-Content $State -Raw | ConvertFrom-Json
    if ($old) { $old.PSObject.Properties | ForEach-Object { $backup[$_.Name] = $_.Value } }
}
function Save-State { $backup | ConvertTo-Json -Depth 4 | Set-Content $State -Encoding UTF8 }

function Set-Reg($Path, $Name, $Value, $Type = 'DWord') {
    $key = $Path + '|' + $Name
    if (-not $backup.ContainsKey($key)) {
        $p = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        $backup[$key] = @{ existed = [bool]$p; value = $(if ($p) { $p.$Name } else { $null }); type = $Type }
    }
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Undo-All {
    foreach ($k in @($backup.Keys)) {
        if ($k -eq '_powerplan') { powercfg /setactive $backup[$k] | Out-Null; continue }
        $parts = $k -split '\|', 2
        $e = $backup[$k]
        if ($e.existed) { New-ItemProperty -Path $parts[0] -Name $parts[1] -Value $e.value -PropertyType $e.type -Force | Out-Null }
        else { Remove-ItemProperty -Path $parts[0] -Name $parts[1] -ErrorAction SilentlyContinue }
    }
    $backup.Clear()
    if (Test-Path $State) { Remove-Item $State -Force }
}

# Finds Fortnite via the Epic Games Launcher manifest (works on any drive)
function Get-FortniteExe {
    $f = Join-Path $env:ProgramData 'Epic\UnrealEngineLauncher\LauncherInstalled.dat'
    if (Test-Path $f) {
        $app = (Get-Content $f -Raw | ConvertFrom-Json).InstallationList | Where-Object AppName -eq 'Fortnite' | Select-Object -First 1
        if ($app) {
            $exe = Join-Path $app.InstallLocation 'FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe'
            if (Test-Path $exe) { return $exe }
        }
    }
    return $null
}

$Tweaks = @(
  @{ Name = 'Ultimate Performance power plan (falls back to High Performance)'; Run = {
      if (-not $backup.ContainsKey('_powerplan') -and ((powercfg /getactivescheme) -match '([0-9a-fA-F-]{36})')) { $backup['_powerplan'] = $matches[1] }
      $out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
      if ($out -match '([0-9a-fA-F-]{36})') { powercfg /setactive $matches[1] }
      else { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c }
  }},
  @{ Name = 'Game Mode on, Game Bar / background recording off'; Run = {
      Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
      Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
      Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
      Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
  }},
  @{ Name = 'Fortnite: high CPU priority, high-performance GPU, no fullscreen optimizations'; Run = {
      $ifeo = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\FortniteClient-Win64-Shipping.exe\PerfOptions'
      Set-Reg $ifeo 'CpuPriorityClass' 3
      $exe = Get-FortniteExe
      if ($exe) {
          Set-Reg 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' $exe 'GpuPreference=2;' 'String'
          Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' $exe '~ DISABLEDXMAXIMIZEDWINDOWEDMODE' 'String'
      } else { Write-Warning 'Fortnite install not found via Epic Launcher - GPU/fullscreen part skipped.' }
  }},
  @{ Name = 'Hardware-accelerated GPU scheduling (needs supported GPU, reboot)'; Run = {
      Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
  }},
  @{ Name = 'Multimedia scheduler: prioritise games over background tasks'; Run = {
      $m = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
      Set-Reg $m 'SystemResponsiveness' 10
      Set-Reg ($m + '\Tasks\Games') 'GPU Priority' 8
      Set-Reg ($m + '\Tasks\Games') 'Priority' 6
      Set-Reg ($m + '\Tasks\Games') 'Scheduling Category' 'High' 'String'
      Set-Reg ($m + '\Tasks\Games') 'SFIO Priority' 'High' 'String'
  }},
  @{ Name = 'Network: disable Nagle / delayed ACK on active adapters (small latency gain)'; Run = {
      Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object {
          $p = Get-ItemProperty $_.PSPath
          if ($p.DhcpIPAddress -or $p.IPAddress) {
              Set-Reg $_.PSPath 'TcpAckFrequency' 1
              Set-Reg $_.PSPath 'TCPNoDelay' 1
          }
      }
  }},
  @{ Name = 'Mouse: disable pointer acceleration (re-login needed)'; Run = {
      Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
      Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
      Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
  }}
)

if ($Undo) { Undo-All; Write-Host 'Everything reverted. Restart Windows.' -ForegroundColor Green; return }

if ($All) { $sel = 1..$Tweaks.Count }
elseif ($Only) { $sel = $Only }
else {
    Write-Host ''
    Write-Host ' namtweaks2 - free gaming tweaks' -ForegroundColor Cyan
    for ($i = 0; $i -lt $Tweaks.Count; $i++) { Write-Host (' [{0}] {1}' -f ($i + 1), $Tweaks[$i].Name) }
    Write-Host ' [A] Apply all   [U] Undo everything   [Q] Quit'
    $c = Read-Host 'Choose (e.g. 1,3,5)'
    switch -Regex ($c) {
        '^[Qq]' { return }
        '^[Uu]' { Undo-All; Write-Host 'Everything reverted.' -ForegroundColor Green; return }
        '^[Aa]' { $sel = 1..$Tweaks.Count }
        default { $sel = $c -split '[,\s]+' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ } }
    }
}

try {
    Enable-ComputerRestore -Drive ($env:SystemDrive + '\')
    Checkpoint-Computer -Description 'namtweaks2' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
} catch { Write-Warning ('Restore point skipped: ' + $_.Exception.Message) }

foreach ($n in $sel) {
    if ($n -ge 1 -and $n -le $Tweaks.Count) {
        Write-Host ('Applying: ' + $Tweaks[$n - 1].Name) -ForegroundColor Cyan
        & $Tweaks[$n - 1].Run
    }
}
Save-State
Write-Host 'Done. Restart Windows. Revert any time with: .\namtweaks2.ps1 -Undo' -ForegroundColor Green
