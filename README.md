# namtweaks2

Free, open-source Windows tweaks for Fortnite in **one script** with a menu. Original code, no keys, no obfuscation, read it before you run it.

## Tweaks (pick any or all)
1. Ultimate Performance power plan (falls back to High Performance)
2. Game Mode on, Xbox Game Bar / background recording off
3. Fortnite: high CPU priority, high-performance GPU, fullscreen optimizations off (install found automatically via Epic Launcher)
4. Hardware-accelerated GPU scheduling (supported GPUs only)
5. Multimedia scheduler tuned for games
6. Network: Nagle / delayed ACK off on active adapters (small latency gain)
7. Mouse pointer acceleration off

## Why it is safer than typical tweak packs
- Creates a **restore point** before changing anything
- Saves the **exact original value** of every setting, so `-Undo` restores *your* values, not generic defaults
- Auto-detects Fortnite instead of assuming `C:\Program Files`
- No Defender / mitigation / service disabling

## Usage
Run PowerShell **as administrator**:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\namtweaks2.ps1            # interactive menu
.\namtweaks2.ps1 -All       # everything
.\namtweaks2.ps1 -Only 1,3  # selected tweaks
.\namtweaks2.ps1 -Undo      # revert everything
```
Restart Windows afterwards. `undo.ps1` is a shortcut for `-Undo`.

## Recommended in-game settings
- Rendering mode: **Performance** (best FPS) or DirectX 11
- Resolution: native, 3D resolution 100%
- Frame rate limit: monitor refresh rate or a stable value you can hold
- V-Sync off, Motion Blur off, Nanite/Lumen/Virtual Shadows low or off on weaker PCs
- NVIDIA Reflex: **On + Boost**

## Disclaimer
Provided as is, use at your own risk. Gains depend on your hardware; some tweaks (5, 6) are small. Not affiliated with Epic Games or any other tweak project. MIT licensed.
