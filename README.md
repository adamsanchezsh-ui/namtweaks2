# namtweaks2

Free, open-source gaming tweaks for Fortnite on Windows 10/11.

**Modern EMTweaks-style dark UI** with sidebar, cards and live system gauges + full tweak suite.

## Desktop App (recommended)

1. Go to **Actions** tab → latest **Build exe** run → download **namtweaks2-exe** artifact
2. Extract `namtweaks2.exe`
3. Right-click → **Run as administrator** (or create a desktop shortcut)

Alternatively double-click `namtweaks2.bat` (launches the same UI).

### Features

**Home**
- Live CPU / RAM gauges
- Live ping monitor
- Quick action buttons (Input reducer, Ping stabilizer, Game booster)

**Crosshair**
- Click-through always-on-top overlay
- Styles: Cross / Dot / Cross+Dot
- Length, thickness, gap, color, outline, position (pixel perfect)
- Settings auto-saved

**Boosters**
- Input delay reducer (0.5 ms timer, no mouse accel, power throttling off)
- Ping stabilizer (Nagle off, network throttling off, DNS flush)
- Game booster (close background apps + Fortnite High priority)
- Auto-boost when Fortnite starts
- Full optimizer menu + complete Revert

## Full optimizer script

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\\namtweaks2.ps1            # interactive menu
.\\namtweaks2.ps1 -All       # apply everything
.\\namtweaks2.ps1 -Undo      # revert everything
```

## Notes
- Source is open (MIT). No keys, no obfuscation.
- Crosshair requires Windowed Fullscreen in Fortnite.
- Compiled .exe may trigger AV false positives (PS2EXE) — source is right here.
- Use at your own risk. Not affiliated with Epic Games.
