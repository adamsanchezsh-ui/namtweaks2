# namtweaks2

Free, open-source gaming tweaks for Fortnite on Windows 10/11: a **modern dark-blue GUI app** (crosshair overlay + boosters) and a **tweak script**. Original code, no keys, no obfuscation.

## App (`namtweaks2.bat`)

Double-click `namtweaks2.bat` and accept the admin prompt. Or download `namtweaks2.exe` from the **Actions** tab (Build exe → Artifacts).

### New modern UI
- Deep dark theme with blue accents
- Clean header + rounded modern buttons
- Better spacing and readability
- Same powerful features, just looks 10× better

**Crosshair tab**
- Overlay is click-through and always on top
- Styles: cross, dot, cross + dot; length, thickness, gap, color, black outline
- **Position X / Y** relative to screen center: click a box and use arrow keys / mouse wheel to move it pixel by pixel
- Settings saved automatically (`%APPDATA%\namtweaks2\config.json`)
- Fortnite must be in **Windowed Fullscreen**, otherwise overlays are hidden

**Boosters tab**
- **Input delay reducer**: 0.5 ms timer resolution (active while the app is open), mouse acceleration off, power throttling off, multimedia scheduler tuned
- **Ping stabilizer**: Nagle / delayed ACK off, network throttling off, DNS flush, plus a live ping / range / loss monitor
- **Game booster**: closes the background apps you list (editable) and sets Fortnite to High priority; optional auto-boost when Fortnite starts
- **Revert ALL**: restores your exact original values

## Tweak script (`namtweaks2.ps1`)
Menu with 7 tweaks (power plan, Game Mode / Game Bar, Fortnite priority + GPU + fullscreen optimizations, HAGS, multimedia scheduler, Nagle, mouse). Creates a restore point first.

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\namtweaks2.ps1            # menu
.\namtweaks2.ps1 -All       # everything
.\namtweaks2.ps1 -Undo      # revert everything (also reverts app boosters)
```

## Recommended in-game settings
Performance rendering mode (or DX11), native resolution, V-Sync off, FPS limit = refresh rate, NVIDIA Reflex On + Boost.

## Notes
- The crosshair is a separate window and does not touch the game, but any overlay is used at your own risk with anti-cheat
- Gains depend on hardware; some tweaks are small
- The compiled exe may trigger antivirus false positives (PS2EXE), the source is right here
- Not affiliated with Epic Games or any other tweak project. MIT licensed. Use at your own risk.
