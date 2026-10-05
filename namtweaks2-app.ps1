#Requires -RunAsAdministrator
# namtweaks2 - modern EMTweaks-style dark UI (sidebar + cards + gauges)
# crosshair overlay + boosters + system monitor
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, System.Management
Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using System.Runtime.InteropServices;

public static class Native {
  [DllImport("ntdll.dll")] public static extern int NtSetTimerResolution(uint d, bool s, out uint c);
  [DllImport("user32.dll")] static extern bool SystemParametersInfo(uint a, uint b, int[] c, uint d);
  public static bool NoMouseAccel() { return SystemParametersInfo(4, 0, new int[] { 0, 0, 0 }, 0); }
}

public class Xhair : Form {
  public int Style = 2, Len = 10, Thick = 2, Gap = 4;
  public bool Outline = true;
  public Color Col = Color.Lime;
  public Xhair() {
    FormBorderStyle = FormBorderStyle.None; ShowInTaskbar = false; TopMost = true;
    StartPosition = FormStartPosition.Manual; BackColor = Color.Magenta; TransparencyKey = Color.Magenta;
    DoubleBuffered = true; Size = new Size(200, 200);
  }
  protected override bool ShowWithoutActivation { get { return true; } }
  protected override CreateParams CreateParams {
    get { var p = base.CreateParams; p.ExStyle |= 0x80000 | 0x20 | 0x80 | 0x8000000; return p; }
  }
  public void Place(int ox, int oy) {
    var b = Screen.PrimaryScreen.Bounds;
    Location = new Point(b.Left + b.Width / 2 - Width / 2 + ox, b.Top + b.Height / 2 - Height / 2 + oy);
  }
  void Arms(Graphics g, Color c, int w) {
    int cx = Width / 2, cy = Height / 2;
    using (var p = new Pen(c, w)) using (var b = new SolidBrush(c)) {
      if (Style != 1) {
        g.DrawLine(p, cx - Gap - Len, cy, cx - Gap, cy); g.DrawLine(p, cx + Gap, cy, cx + Gap + Len, cy);
        g.DrawLine(p, cx, cy - Gap - Len, cx, cy - Gap); g.DrawLine(p, cx, cy + Gap, cx, cy + Gap + Len);
      }
      if (Style != 0) { int r = Math.Max(1, Thick) + (w - Thick) / 2; g.FillEllipse(b, cx - r, cy - r, 2 * r, 2 * r); }
    }
  }
  protected override void OnPaint(PaintEventArgs e) {
    e.Graphics.Clear(Color.Magenta);
    if (Outline) Arms(e.Graphics, Color.Black, Thick + 2);
    Arms(e.Graphics, Col, Thick);
  }
}

// Circular gauge control
public class Gauge : Control {
  public float Value = 0; // 0-100
  public Color Accent = Color.FromArgb(99, 102, 241);
  public string Label = "CPU";
  public Gauge() {
    DoubleBuffered = true;
    Size = new Size(140, 160);
    BackColor = Color.Transparent;
  }
  protected override void OnPaint(PaintEventArgs e) {
    e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
    int size = Math.Min(Width, Height - 30) - 10;
    int x = (Width - size) / 2;
    int y = 8;
    var rect = new Rectangle(x, y, size, size);
    float start = -90;
    float sweep = 360f * Math.Min(100, Math.Max(0, Value)) / 100f;

    using (var bg = new Pen(Color.FromArgb(40, 40, 60), 10))
    using (var fg = new Pen(Accent, 10) { StartCap = LineCap.Round, EndCap = LineCap.Round }) {
      e.Graphics.DrawArc(bg, rect, 0, 360);
      if (sweep > 0.5f) e.Graphics.DrawArc(fg, rect, start, sweep);
    }
    string pct = ((int)Value).ToString() + "%";
    using (var f = new Font("Segoe UI Semibold", 16f))
    using (var b = new SolidBrush(Color.White)) {
      var sz = e.Graphics.MeasureString(pct, f);
      e.Graphics.DrawString(pct, f, b, x + (size - sz.Width) / 2, y + (size - sz.Height) / 2 - 2);
    }
    using (var f2 = new Font("Segoe UI", 9f))
    using (var b2 = new SolidBrush(Color.FromArgb(160, 160, 180))) {
      var sz2 = e.Graphics.MeasureString(Label, f2);
      e.Graphics.DrawString(Label, f2, b2, (Width - sz2.Width) / 2, y + size + 6);
    }
  }
}

// Modern nav button
public class NavBtn : Button {
  public bool Active = false;
  public Color Accent = Color.FromArgb(99, 102, 241);
  public NavBtn() {
    FlatStyle = FlatStyle.Flat;
    FlatAppearance.BorderSize = 0;
    ForeColor = Color.FromArgb(180, 180, 200);
    Font = new Font("Segoe UI Semibold", 10f);
    TextAlign = ContentAlignment.MiddleLeft;
    Cursor = Cursors.Hand;
    Height = 42;
    Padding = new Padding(16, 0, 0, 0);
  }
  protected override void OnPaint(PaintEventArgs e) {
    e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
    var bg = Active ? Color.FromArgb(35, 35, 55) : Color.Transparent;
    using (var b = new SolidBrush(bg)) e.Graphics.FillRectangle(b, ClientRectangle);
    if (Active) {
      using (var p = new SolidBrush(Accent))
        e.Graphics.FillRectangle(p, 0, 8, 4, Height - 16);
    }
    TextRenderer.DrawText(e.Graphics, Text, Font, new Rectangle(18, 0, Width - 20, Height),
      Active ? Color.White : ForeColor, TextFormatFlags.VerticalCenter | TextFormatFlags.Left);
  }
}

// Rounded card panel
public class Card : Panel {
  public int Radius = 12;
  public Card() {
    DoubleBuffered = true;
    BackColor = Color.FromArgb(22, 22, 36);
  }
  protected override void OnPaint(PaintEventArgs e) {
    e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
    using (var path = RoundRect(ClientRectangle, Radius))
    using (var b = new SolidBrush(BackColor)) {
      e.Graphics.FillPath(b, path);
    }
  }
  static GraphicsPath RoundRect(Rectangle r, int rad) {
    var p = new GraphicsPath();
    int d = rad * 2;
    p.AddArc(r.X, r.Y, d, d, 180, 90);
    p.AddArc(r.Right - d - 1, r.Y, d, d, 270, 90);
    p.AddArc(r.Right - d - 1, r.Bottom - d - 1, d, d, 0, 90);
    p.AddArc(r.X, r.Bottom - d - 1, d, d, 90, 90);
    p.CloseFigure();
    return p;
  }
}

// Modern button
public class ModernButton : Button {
  public Color NormalColor = Color.FromArgb(79, 70, 229);
  public Color HoverColor  = Color.FromArgb(99, 102, 241);
  public Color PressColor  = Color.FromArgb(67, 56, 202);
  private bool hover = false, press = false;
  public ModernButton() {
    FlatStyle = FlatStyle.Flat;
    FlatAppearance.BorderSize = 0;
    ForeColor = Color.White;
    Font = new Font("Segoe UI Semibold", 9.5f);
    Cursor = Cursors.Hand;
    BackColor = NormalColor;
  }
  protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
  protected override void OnMouseLeave(EventArgs e) { hover = false; press = false; Invalidate(); base.OnMouseLeave(e); }
  protected override void OnMouseDown(MouseEventArgs e) { press = true; Invalidate(); base.OnMouseDown(e); }
  protected override void OnMouseUp(MouseEventArgs e) { press = false; Invalidate(); base.OnMouseUp(e); }
  protected override void OnPaint(PaintEventArgs e) {
    e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
    var col = press ? PressColor : (hover ? HoverColor : NormalColor);
    using (var b = new SolidBrush(col))
    using (var path = RoundRect(ClientRectangle, 8)) {
      e.Graphics.FillPath(b, path);
    }
    TextRenderer.DrawText(e.Graphics, Text, Font, ClientRectangle, ForeColor,
      TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
  }
  static GraphicsPath RoundRect(Rectangle r, int rad) {
    var p = new GraphicsPath();
    int d = rad * 2;
    p.AddArc(r.X, r.Y, d, d, 180, 90);
    p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
    p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
    p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
    p.CloseFigure();
    return p;
  }
}
'@

[Windows.Forms.Application]::EnableVisualStyles()
$root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path ([Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) }
$AppDir = Join-Path $env:APPDATA 'namtweaks2'; $CfgFile = Join-Path $AppDir 'config.json'
$Dir = Join-Path $env:ProgramData 'namtweaks2'; $State = Join-Path $Dir 'backup.json'
New-Item $AppDir, $Dir -ItemType Directory -Force | Out-Null

# ---------- theme (EMTweaks-like purple/dark) ----------
$Bg       = [Drawing.Color]::FromArgb(12, 12, 20)
$Sidebar  = [Drawing.Color]::FromArgb(18, 18, 30)
$CardBg   = [Drawing.Color]::FromArgb(22, 22, 36)
$Accent   = [Drawing.Color]::FromArgb(99, 102, 241)   # indigo/purple
$Accent2  = [Drawing.Color]::FromArgb(139, 92, 246)
$TextMain = [Drawing.Color]::FromArgb(240, 240, 250)
$TextMute = [Drawing.Color]::FromArgb(150, 150, 170)
$Success  = [Drawing.Color]::FromArgb(34, 197, 94)
$Danger   = [Drawing.Color]::FromArgb(239, 68, 68)

$Conf = @{ Style = 2; Len = 10; Thick = 2; Gap = 4; X = 0; Y = 0; Color = '#00FF00'; Outline = $true; Show = $true; Kill = 'OneDrive,Spotify,Teams,Skype,Dropbox'; Auto = $false }
if (Test-Path $CfgFile) { (Get-Content $CfgFile -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Conf[$_.Name] = $_.Value } }

$backup = @{}
if (Test-Path $State) { $o = Get-Content $State -Raw | ConvertFrom-Json; if ($o) { $o.PSObject.Properties | ForEach-Object { $backup[$_.Name] = $_.Value } } }
function Save-State { $script:backup | ConvertTo-Json -Depth 4 | Set-Content $State -Encoding UTF8 }
function Set-Reg($Path, $Name, $Value, $Type = 'DWord') {
    $key = $Path + '|' + $Name
    if (-not $script:backup.ContainsKey($key)) {
        $p = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        $script:backup[$key] = @{ existed = [bool]$p; value = $(if ($p) { $p.$Name } else { $null }); type = $Type }
    }
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}
function Undo-All {
    foreach ($k in @($script:backup.Keys)) {
        if ($k -eq '_powerplan') { powercfg /setactive $script:backup[$k] | Out-Null; continue }
        $s = $k -split '\|', 2; $e = $script:backup[$k]
        if ($e.existed) { New-ItemProperty -Path $s[0] -Name $s[1] -Value $e.value -PropertyType $e.type -Force | Out-Null }
        else { Remove-ItemProperty -Path $s[0] -Name $s[1] -ErrorAction SilentlyContinue }
    }
    $script:backup.Clear(); if (Test-Path $State) { Remove-Item $State -Force }
}

# ---------------- crosshair ----------------
$x = New-Object Xhair
function Apply-Cross {
    $c = $script:Conf; $x = $script:x
    $x.Style = [int]$c.Style; $x.Len = [int]$c.Len; $x.Thick = [int]$c.Thick; $x.Gap = [int]$c.Gap; $x.Outline = [bool]$c.Outline
    $x.Col = [Drawing.ColorTranslator]::FromHtml($c.Color)
    $x.Place([int]$c.X, [int]$c.Y); $x.Invalidate()
    if ($c.Show) { if (-not $x.Visible) { $x.Show() } } else { $x.Hide() }
    $c | ConvertTo-Json | Set-Content $CfgFile
}

# ---------------- boosters ----------------
function Boost-Input {
    $cur = [uint32]0; [void][Native]::NtSetTimerResolution(5000, $true, [ref]$cur)
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'GlobalTimerResolutionRequests' 1
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 10
    foreach ($n in 'MouseSpeed', 'MouseThreshold1', 'MouseThreshold2') { Set-Reg 'HKCU:\Control Panel\Mouse' $n '0' 'String' }
    [void][Native]::NoMouseAccel(); Save-State
}
function Boost-Ping {
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath
        if ($p.DhcpIPAddress -or $p.IPAddress) { Set-Reg $_.PSPath 'TcpAckFrequency' 1; Set-Reg $_.PSPath 'TCPNoDelay' 1 }
    }
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    ipconfig /flushdns | Out-Null; Save-State
}
$protect = 'explorer', 'winlogon', 'csrss', 'svchost', 'dwm', 'lsass', 'services', 'system', 'smss', 'wininit', 'FortniteClient-Win64-Shipping', 'EasyAntiCheat', 'EpicGamesLauncher'
function Boost-Game {
    $n = 0
    foreach ($name in ($script:Conf.Kill -split '[,\s]+' | Where-Object { $_ -and $protect -notcontains $_ })) {
        Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object { try { $_.Kill(); $n++ } catch {} }
    }
    Get-Process -Name 'FortniteClient-Win64-Shipping' -ErrorAction SilentlyContinue | ForEach-Object { try { $_.PriorityClass = 'High' } catch {} }
    $script:status.Text = "Game boost: closed $n process(es) • Fortnite High priority"
    $script:status.ForeColor = $Success
}

# ===================== MAIN FORM =====================
$form = New-Object Windows.Forms.Form -Property @{
    Text            = 'namtweaks2'
    ClientSize     = '960,640'
    FormBorderStyle= 'FixedSingle'
    MaximizeBox    = $false
    StartPosition  = 'CenterScreen'
    BackColor      = $Bg
    Font           = New-Object Drawing.Font('Segoe UI', 9)
}
try { $form.Icon = [Drawing.Icon]::ExtractAssociatedIcon("$env:SystemRoot\System32\shell32.dll") } catch {}

# ----- SIDEBAR -----
$side = New-Object Windows.Forms.Panel -Property @{
    Left = 0; Top = 0; Width = 210; Height = 640; BackColor = $Sidebar
}
$form.Controls.Add($side)

$logo = New-Object Windows.Forms.Label -Property @{
    Text = 'namtweaks2'; Left = 20; Top = 22; Width = 170; Height = 28
    ForeColor = $TextMain; Font = New-Object Drawing.Font('Segoe UI Semibold', 15)
}
$logoSub = New-Object Windows.Forms.Label -Property @{
    Text = 'Optimization Utility'; Left = 20; Top = 50; Width = 170; Height = 18
    ForeColor = $TextMute; Font = New-Object Drawing.Font('Segoe UI', 8)
}
$side.Controls.AddRange(@($logo, $logoSub))

$navHome = New-Object NavBtn
$navHome.Text = '  Home'
$navHome.Left = 8
$navHome.Top = 100
$navHome.Width = 194
$navHome.Active = $true

$navCross = New-Object NavBtn
$navCross.Text = '  Crosshair'
$navCross.Left = 8
$navCross.Top = 146
$navCross.Width = 194

$navBoost = New-Object NavBtn
$navBoost.Text = '  Boosters'
$navBoost.Left = 8
$navBoost.Top = 192
$navBoost.Width = 194

$side.Controls.AddRange(@($navHome, $navCross, $navBoost))

$status = New-Object Windows.Forms.Label -Property @{
    Left = 16; Top = 600; Width = 180; Height = 30
    Text = 'Ready'; ForeColor = $TextMute; Font = New-Object Drawing.Font('Segoe UI', 8)
}
$side.Controls.Add($status)

# ----- CONTENT AREA -----
$content = New-Object Windows.Forms.Panel -Property @{
    Left = 210; Top = 0; Width = 750; Height = 640; BackColor = $Bg
}
$form.Controls.Add($content)

# ===== HOME PAGE =====
$pageHome = New-Object Windows.Forms.Panel -Property @{
    Left = 0; Top = 0; Width = 750; Height = 640; BackColor = $Bg; Visible = $true
}
$content.Controls.Add($pageHome)

$welcome = New-Object Windows.Forms.Label -Property @{
    Text = 'Welcome back to namtweaks2'; Left = 28; Top = 24; Width = 500; Height = 32
    ForeColor = $TextMain; Font = New-Object Drawing.Font('Segoe UI Semibold', 18)
}
$welcomeSub = New-Object Windows.Forms.Label -Property @{
    Text = 'Performance, optimization and Fortnite tweaks - all in one.'; Left = 28; Top = 56; Width = 500; Height = 20
    ForeColor = $TextMute; Font = New-Object Drawing.Font('Segoe UI', 9.5)
}
$pageHome.Controls.AddRange(@($welcome, $welcomeSub))

# Gauges card
$gaugeCard = New-Object Card
$gaugeCard.Left = 28; $gaugeCard.Top = 100; $gaugeCard.Width = 460; $gaugeCard.Height = 190
$pageHome.Controls.Add($gaugeCard)

$gCpu = New-Object Gauge; $gCpu.Label = 'CPU Usage'; $gCpu.Left = 30; $gCpu.Top = 16; $gCpu.Width = 130; $gCpu.Height = 160
$gRam = New-Object Gauge; $gRam.Label = 'RAM Usage'; $gRam.Left = 170; $gRam.Top = 16; $gRam.Width = 130; $gRam.Height = 160; $gRam.Accent = [Drawing.Color]::FromArgb(139, 92, 246)
$gPing = New-Object Gauge; $gPing.Label = 'Ping (ms)'; $gPing.Left = 310; $gPing.Top = 16; $gPing.Width = 130; $gPing.Height = 160; $gPing.Accent = [Drawing.Color]::FromArgb(34, 197, 94)
$gaugeCard.Controls.AddRange(@($gCpu, $gRam, $gPing))

# Quick actions card
$actCard = New-Object Card
$actCard.Left = 510; $actCard.Top = 100; $actCard.Width = 210; $actCard.Height = 190
$pageHome.Controls.Add($actCard)

$actTitle = New-Object Windows.Forms.Label -Property @{
    Text = 'Quick Actions'; Left = 16; Top = 16; Width = 180; Height = 22
    ForeColor = $TextMain; Font = New-Object Drawing.Font('Segoe UI Semibold', 11)
}
$actCard.Controls.Add($actTitle)

$btnQuickInput = New-Object ModernButton
$btnQuickInput.Text = 'Input Reducer'; $btnQuickInput.Left = 16; $btnQuickInput.Top = 50; $btnQuickInput.Width = 178; $btnQuickInput.Height = 34
$btnQuickInput.add_Click({ Boost-Input; $script:status.Text = 'Input reducer applied'; $script:status.ForeColor = $Success })
$btnQuickPing = New-Object ModernButton
$btnQuickPing.Text = 'Ping Stabilizer'; $btnQuickPing.Left = 16; $btnQuickPing.Top = 92; $btnQuickPing.Width = 178; $btnQuickPing.Height = 34
$btnQuickPing.add_Click({ Boost-Ping; $script:status.Text = 'Ping stabilizer applied'; $script:status.ForeColor = $Success })
$btnQuickGame = New-Object ModernButton
$btnQuickGame.Text = 'Game Booster'; $btnQuickGame.Left = 16; $btnQuickGame.Top = 134; $btnQuickGame.Width = 178; $btnQuickGame.Height = 34
$btnQuickGame.add_Click({ Boost-Game })
$actCard.Controls.AddRange(@($btnQuickInput, $btnQuickPing, $btnQuickGame))

# Info cards bottom
$info1 = New-Object Card
$info1.Left = 28; $info1.Top = 310; $info1.Width = 340; $info1.Height = 140
$pageHome.Controls.Add($info1)
$i1t = New-Object Windows.Forms.Label -Property @{
    Text = 'Crosshair Overlay'; Left = 18; Top = 16; Width = 300; Height = 22
    ForeColor = $TextMain; Font = New-Object Drawing.Font('Segoe UI Semibold', 11)
}
$i1d = New-Object Windows.Forms.Label -Property @{
    Text = 'Click-through always-on-top crosshair.`nStyle, color, position fully adjustable.`nSaved automatically.'; Left = 18; Top = 46; Width = 300; Height = 70
    ForeColor = $TextMute; Font = New-Object Drawing.Font('Segoe UI', 9)
}
$info1.Controls.AddRange(@($i1t, $i1d))

$info2 = New-Object Card
$info2.Left = 386; $info2.Top = 310; $info2.Width = 334; $info2.Height = 140
$pageHome.Controls.Add($info2)
$i2t = New-Object Windows.Forms.Label -Property @{
    Text = 'Full Optimizer'; Left = 18; Top = 16; Width = 300; Height = 22
    ForeColor = $TextMain; Font = New-Object Drawing.Font('Segoe UI Semibold', 11)
}
$i2d = New-Object Windows.Forms.Label -Property @{
    Text = 'Power plan, Game Mode, HAGS, Nagle,`nmouse accel, Fortnite priority + more.`nEverything is fully reversible.'; Left = 18; Top = 46; Width = 300; Height = 70
    ForeColor = $TextMute; Font = New-Object Drawing.Font('Segoe UI', 9)
}
$info2.Controls.AddRange(@($i2t, $i2d))

$btnOpenOpt = New-Object ModernButton
$btnOpenOpt.Text = 'Open full optimizer menu'; $btnOpenOpt.Left = 28; $btnOpenOpt.Top = 470; $btnOpenOpt.Width = 220; $btnOpenOpt.Height = 38
$btnOpenOpt.add_Click({ Start-Process powershell -ArgumentList '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $root 'namtweaks2.ps1') })
$pageHome.Controls.Add($btnOpenOpt)

$btnRevert = New-Object ModernButton
$btnRevert.Text = 'Revert ALL changes'; $btnRevert.Left = 260; $btnRevert.Top = 470; $btnRevert.Width = 180; $btnRevert.Height = 38
$btnRevert.NormalColor = [Drawing.Color]::FromArgb(127, 29, 29)
$btnRevert.HoverColor  = [Drawing.Color]::FromArgb(153, 27, 27)
$btnRevert.PressColor  = [Drawing.Color]::FromArgb(100, 20, 20)
$btnRevert.add_Click({ Undo-All; $script:status.Text = 'Everything reverted. Restart Windows.'; $script:status.ForeColor = $Danger })
$pageHome.Controls.Add($btnRevert)

# ===== CROSSHAIR PAGE =====
$pageCross = New-Object Windows.Forms.Panel -Property @{
    Left = 0; Top = 0; Width = 750; Height = 640; BackColor = $Bg; Visible = $false
}
$content.Controls.Add($pageCross)

$cxTitle = New-Object Windows.Forms.Label -Property @{
    Text = 'Crosshair'; Left = 28; Top = 24; Width = 300; Height = 32
    ForeColor = $TextMain; Font = New-Object Drawing.Font('Segoe UI Semibold', 18)
}
$pageCross.Controls.Add($cxTitle)

$cxCard = New-Object Card
$cxCard.Left = 28; $cxCard.Top = 70; $cxCard.Width = 480; $cxCard.Height = 480
$pageCross.Controls.Add($cxCard)

function MakeLabel($parent, $text, $x, $y, $w = 140) {
    $l = New-Object Windows.Forms.Label -Property @{
        Text = $text; Left = $x; Top = $y; Width = $w; Height = 22
        ForeColor = $TextMute; Font = New-Object Drawing.Font('Segoe UI', 9)
    }
    $parent.Controls.Add($l); $l
}
function MakeNum($parent, $key, $min, $max, $x, $y) {
    $v = [Math]::Min([Math]::Max([int]$Conf[$key], $min), $max)
    $n = New-Object Windows.Forms.NumericUpDown -Property @{
        Minimum = $min; Maximum = $max; Value = $v; Tag = $key
        Left = $x; Top = $y; Width = 100; Height = 28
        BackColor = [Drawing.Color]::FromArgb(30, 30, 48); ForeColor = $TextMain; BorderStyle = 'FixedSingle'
        Font = New-Object Drawing.Font('Segoe UI', 10)
    }
    $n.add_ValueChanged({ $script:Conf[$this.Tag] = [int]$this.Value; Apply-Cross })
    $parent.Controls.Add($n); $n
}

$yy = 24
MakeLabel $cxCard 'Style' 24 $yy
$cb = New-Object Windows.Forms.ComboBox -Property @{
    DropDownStyle = 'DropDownList'; Left = 180; Top = $yy; Width = 240; Height = 28
    BackColor = [Drawing.Color]::FromArgb(30, 30, 48); ForeColor = $TextMain; FlatStyle = 'Flat'
    Font = New-Object Drawing.Font('Segoe UI', 10)
}
[void]$cb.Items.AddRange(@('Cross', 'Dot', 'Cross + Dot'))
$cb.SelectedIndex = [int]$Conf.Style
$cb.add_SelectedIndexChanged({ $script:Conf.Style = $this.SelectedIndex; Apply-Cross })
$cxCard.Controls.Add($cb)
$yy += 48
MakeLabel $cxCard 'Length' 24 $yy
MakeNum $cxCard 'Len' 1 80 180 $yy | Out-Null
$yy += 42
MakeLabel $cxCard 'Thickness' 24 $yy
MakeNum $cxCard 'Thick' 1 12 180 $yy | Out-Null
$yy += 42
MakeLabel $cxCard 'Gap' 24 $yy
MakeNum $cxCard 'Gap' 0 60 180 $yy | Out-Null
$yy += 42
MakeLabel $cxCard 'Position X' 24 $yy
$nx = MakeNum $cxCard 'X' -900 900 180 $yy
$yy += 42
MakeLabel $cxCard 'Position Y' 24 $yy
$ny = MakeNum $cxCard 'Y' -900 900 180 $yy
$yy += 48
MakeLabel $cxCard 'Color' 24 $yy
$bc = New-Object Windows.Forms.Button -Property @{
    Text = '  Pick color  '; Left = 180; Top = $yy; Width = 130; Height = 30
    FlatStyle = 'Flat'; FlatAppearance = @{ BorderSize = 0 }
    BackColor = [Drawing.ColorTranslator]::FromHtml($Conf.Color)
    ForeColor = [Drawing.Color]::White; Cursor = [Windows.Forms.Cursors]::Hand
    Font = New-Object Drawing.Font('Segoe UI Semibold', 9)
}
$bc.add_Click({
    $d = New-Object Windows.Forms.ColorDialog
    if ($d.ShowDialog() -eq 'OK') {
        $script:Conf.Color = [Drawing.ColorTranslator]::ToHtml($d.Color)
        $this.BackColor = $d.Color; Apply-Cross
    }
})
$cxCard.Controls.Add($bc)
$yy += 48
$co = New-Object Windows.Forms.CheckBox -Property @{
    Text = 'Black outline'; Left = 24; Top = $yy; Width = 160; Height = 26
    ForeColor = $TextMain; Checked = [bool]$Conf.Outline; FlatStyle = 'Flat'
    Font = New-Object Drawing.Font('Segoe UI', 10)
}
$co.add_CheckedChanged({ $script:Conf.Outline = $this.Checked; Apply-Cross })
$cxCard.Controls.Add($co)
$cs = New-Object Windows.Forms.CheckBox -Property @{
    Text = 'Show crosshair'; Left = 200; Top = $yy; Width = 160; Height = 26
    ForeColor = $TextMain; Checked = [bool]$Conf.Show; FlatStyle = 'Flat'
    Font = New-Object Drawing.Font('Segoe UI', 10)
}
$cs.add_CheckedChanged({ $script:Conf.Show = $this.Checked; Apply-Cross })
$cxCard.Controls.Add($cs)
$yy += 48
$btnCenter = New-Object ModernButton
$btnCenter.Text = 'Center (X=0, Y=0)'; $btnCenter.Left = 24; $btnCenter.Top = $yy; $btnCenter.Width = 200; $btnCenter.Height = 36
$btnCenter.add_Click({ $script:nx.Value = 0; $script:ny.Value = 0 })
$cxCard.Controls.Add($btnCenter)

$hint = New-Object Windows.Forms.Label -Property @{
    Left = 24; Top = 420; Width = 430; Height = 50
    ForeColor = $TextMute; Font = New-Object Drawing.Font('Segoe UI', 8.5)
    Text = "Use arrow keys / mouse wheel on number boxes to nudge pixel by pixel.`nFortnite must be Windowed Fullscreen."
}
$cxCard.Controls.Add($hint)

# ===== BOOSTERS PAGE =====
$pageBoost = New-Object Windows.Forms.Panel -Property @{
    Left = 0; Top = 0; Width = 750; Height = 640; BackColor = $Bg; Visible = $false
}
$content.Controls.Add($pageBoost)

$bTitle = New-Object Windows.Forms.Label -Property @{
    Text = 'Boosters'; Left = 28; Top = 24; Width = 300; Height = 32
    ForeColor = $TextMain; Font = New-Object Drawing.Font('Segoe UI Semibold', 18)
}
$pageBoost.Controls.Add($bTitle)

$bCard = New-Object Card
$bCard.Left = 28; $bCard.Top = 70; $bCard.Width = 520; $bCard.Height = 500
$pageBoost.Controls.Add($bCard)

$by = 24
$btnBI = New-Object ModernButton
$btnBI.Text = 'Input delay reducer  •  0.5 ms timer + no mouse accel'
$btnBI.Left = 24; $btnBI.Top = $by; $btnBI.Width = 470; $btnBI.Height = 42
$btnBI.add_Click({ Boost-Input; $script:status.Text = 'Input delay reducer applied'; $script:status.ForeColor = $Success })
$bCard.Controls.Add($btnBI)
$by += 56
$btnBP = New-Object ModernButton
$btnBP.Text = 'Ping stabilizer  •  Nagle off + no throttling + flush DNS'
$btnBP.Left = 24; $btnBP.Top = $by; $btnBP.Width = 470; $btnBP.Height = 42
$btnBP.add_Click({ Boost-Ping; $script:status.Text = 'Ping stabilizer applied'; $script:status.ForeColor = $Success })
$bCard.Controls.Add($btnBP)
$by += 60
MakeLabel $bCard 'Ping host' 24 $by 90
$hostBox = New-Object Windows.Forms.TextBox -Property @{
    Text = '1.1.1.1'; Left = 120; Top = $by; Width = 140; Height = 28
    BackColor = [Drawing.Color]::FromArgb(30, 30, 48); ForeColor = $TextMain; BorderStyle = 'FixedSingle'
    Font = New-Object Drawing.Font('Segoe UI', 10)
}
$bCard.Controls.Add($hostBox)
$by += 40
$pingLbl = New-Object Windows.Forms.Label -Property @{
    Left = 24; Top = $by; Width = 470; Height = 24
    ForeColor = $Accent; Font = New-Object Drawing.Font('Segoe UI Semibold', 10)
    Text = 'Ping: measuring...'
}
$bCard.Controls.Add($pingLbl)
$by += 40
MakeLabel $bCard 'Close apps (comma separated)' 24 $by 300
$by += 26
$kb = New-Object Windows.Forms.TextBox -Property @{
    Text = $Conf.Kill; Left = 24; Top = $by; Width = 470; Height = 30
    BackColor = [Drawing.Color]::FromArgb(30, 30, 48); ForeColor = $TextMain; BorderStyle = 'FixedSingle'
    Font = New-Object Drawing.Font('Segoe UI', 10)
}
$kb.add_TextChanged({ $script:Conf.Kill = $this.Text; $script:Conf | ConvertTo-Json | Set-Content $CfgFile })
$bCard.Controls.Add($kb)
$by += 48
$btnBG = New-Object ModernButton
$btnBG.Text = 'Game booster  •  close apps + Fortnite High priority'
$btnBG.Left = 24; $btnBG.Top = $by; $btnBG.Width = 470; $btnBG.Height = 42
$btnBG.add_Click({ Boost-Game })
$bCard.Controls.Add($btnBG)
$by += 56
$ca = New-Object Windows.Forms.CheckBox -Property @{
    Text = 'Auto-boost when Fortnite starts'; Left = 24; Top = $by; Width = 300; Height = 26
    ForeColor = $TextMain; Checked = [bool]$Conf.Auto; FlatStyle = 'Flat'
    Font = New-Object Drawing.Font('Segoe UI', 10)
}
$ca.add_CheckedChanged({ $script:Conf.Auto = $this.Checked; $script:Conf | ConvertTo-Json | Set-Content $CfgFile })
$bCard.Controls.Add($ca)
$by += 50
$btnOpt = New-Object ModernButton
$btnOpt.Text = 'Open full optimizer menu (namtweaks2.ps1)'
$btnOpt.Left = 24; $btnOpt.Top = $by; $btnOpt.Width = 470; $btnOpt.Height = 38
$btnOpt.add_Click({ Start-Process powershell -ArgumentList '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $root 'namtweaks2.ps1') })
$bCard.Controls.Add($btnOpt)
$by += 50
$btnRev = New-Object ModernButton
$btnRev.Text = 'Revert ALL changes'
$btnRev.Left = 24; $btnRev.Top = $by; $btnRev.Width = 470; $btnRev.Height = 38
$btnRev.NormalColor = [Drawing.Color]::FromArgb(127, 29, 29)
$btnRev.HoverColor  = [Drawing.Color]::FromArgb(153, 27, 27)
$btnRev.PressColor  = [Drawing.Color]::FromArgb(100, 20, 20)
$btnRev.add_Click({ Undo-All; $script:status.Text = 'Everything reverted.'; $script:status.ForeColor = $Danger })
$bCard.Controls.Add($btnRev)

# ----- Navigation -----
function Show-Page($name) {
    $pageHome.Visible = ($name -eq 'home')
    $pageCross.Visible = ($name -eq 'cross')
    $pageBoost.Visible = ($name -eq 'boost')
    $navHome.Active = ($name -eq 'home')
    $navCross.Active = ($name -eq 'cross')
    $navBoost.Active = ($name -eq 'boost')
    $navHome.Invalidate(); $navCross.Invalidate(); $navBoost.Invalidate()
}
$navHome.add_Click({ Show-Page 'home' })
$navCross.add_Click({ Show-Page 'cross' })
$navBoost.add_Click({ Show-Page 'boost' })

# ----- Timers: system stats + ping + auto-boost -----
$pg = New-Object Net.NetworkInformation.Ping
$rtt = New-Object Collections.Generic.List[double]
$sent = 0; $lost = 0; $boosted = $false

function Get-CpuUsage {
    try {
        $c = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
        return [double]$c.Average
    } catch { return 0 }
}
function Get-RamUsage {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $used = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
        return [math]::Round(100 * $used / $os.TotalVisibleMemorySize, 1)
    } catch { return 0 }
}

$pt = New-Object Windows.Forms.Timer -Property @{ Interval = 1500 }
$pt.add_Tick({
    # gauges
    $script:gCpu.Value = Get-CpuUsage
    $script:gCpu.Invalidate()
    $script:gRam.Value = Get-RamUsage
    $script:gRam.Invalidate()

    # ping
    $script:sent++
    try {
        $r = $script:pg.Send($script:hostBox.Text, 400)
        if ($r.Status -eq 'Success') {
            $script:rtt.Add([double]$r.RoundtripTime)
            if ($script:rtt.Count -gt 20) { $script:rtt.RemoveAt(0) }
            $script:gPing.Value = [Math]::Min(100, $r.RoundtripTime)  # visual only
            $script:gPing.Invalidate()
        } else { $script:lost++ }
    } catch { $script:lost++ }
    if ($script:rtt.Count) {
        $m = $script:rtt | Measure-Object -Average -Minimum -Maximum
        $script:pingLbl.Text = ("Ping {0} ms  •  range {1} ms  •  loss {2}%" -f `
            [math]::Round($m.Average), ($m.Maximum - $m.Minimum), [math]::Round(100 * $script:lost / $script:sent))
    }

    # auto boost
    if ($script:Conf.Auto) {
        $f = Get-Process -Name 'FortniteClient-Win64-Shipping' -ErrorAction SilentlyContinue
        if ($f -and -not $script:boosted) { Boost-Game; $script:boosted = $true }
        elseif (-not $f) { $script:boosted = $false }
    }
})

Apply-Cross
$pt.Start()
[void]$form.ShowDialog()
$pt.Stop(); $x.Close()
