# namtweaks2

Free, open-source, **safe** Windows tweaks for Fortnite. Original scripts, no paid keys, no obfuscation: read the code before you run it.

## What it does
- Creates a **restore point** first
- Switches to the **High Performance** power plan
- Disables Xbox Game Bar / background recording (Game DVR)
- Enables Windows **Game Mode**
- Sets **High CPU priority** for `FortniteClient-Win64-Shipping.exe`

## Usage
1. Download `namtweaks2.ps1` and `undo.ps1`
2. Right-click PowerShell -> **Run as administrator**
3. `Set-ExecutionPolicy -Scope Process Bypass`
4. `.\namtweaks2.ps1`, then restart Windows

To revert: run `.\undo.ps1` (or use the restore point).

## Recommended in-game settings
- Rendering mode: **Performance** (best FPS) or DirectX 11
- Resolution: native, 3D resolution 100%
- Frame rate limit: monitor refresh rate or a stable value you can hold
- V-Sync off, Motion Blur off, Nanite/Lumen/Virtual Shadows low or off on weaker PCs
- NVIDIA Reflex: **On + Boost**

## Disclaimer
Provided as is, use at your own risk. Not affiliated with Epic Games or any other tweak project. MIT licensed.
