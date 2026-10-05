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

public class Gauge : Control {
  public float Value = 0;
  public Color Accent = Color.FromArgb(99, 102, 241);
  public string Label = "CPU";
  public Gauge() {
    DoubleBuffered = true;
    Size = new Size(130, 160);
    BackColor = Color.Transparent;
  }
  protected override void OnPaint(PaintEventArgs e) {
    e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
    int size = Math.Min(Width, Height - 30) - 10;
    if (size < 10) size = 10;
    int x = (Width - size) / 2;
    int y = 8;
    var rect = new Rectangle(x, y, size, size);
    float sweep = 360f * Math.Min(100f, Math.Max(0f, Value)) / 100f;
    using (var bg = new Pen(Color.FromArgb(40, 40, 60), 10))
    using (var fg = new Pen(Accent, 10)) {
      fg.StartCap = LineCap.Round; fg.EndCap = LineCap.Round;
      e.Graphics.DrawArc(bg, rect, 0, 360);
      if (sweep > 0.5f) e.Graphics.DrawArc(fg, rect, -90, sweep);
    }
    string pct = ((int)Value).ToString() + "%";
    using (var f = new Font("Segoe UI Semibold", 16f))
    using (var b = new SolidBrush(Color.White)) {
      var sz = e.Graphics.MeasureString(pct, f);
      e.Graphics.DrawString(pct, f, b, x + (size - sz.Width) / 2f, y + (size - sz.Height) / 2f - 2);
    }
    using (var f2 = new Font("Segoe UI", 9f))
    using (var b2 = new SolidBrush(Color.FromArgb(160, 160, 180))) {
      var sz2 = e.Graphics.MeasureString(Label, f2);
      e.Graphics.DrawString(Label, f2, b2, (Width - sz2.Width) / 2f, y + size + 6);
    }
  }
}

public class NavBtn : Button {
  public bool Active = false;
  public Color Accent = Color.FromArgb(99, 102, 241);
  public NavBtn() {
    FlatStyle = FlatStyle.Flat; FlatAppearance.BorderSize = 0;
    ForeColor = Color.FromArgb(180, 180, 200);
    Font = new Font("Segoe UI Semibold", 10f);
    TextAlign = ContentAlignment.MiddleLeft; Cursor = Cursors.Hand;
    Size = new Size(194, 42);
  }
  protected override void OnPaint(PaintEventArgs e) {
    e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
    Color bg = Active ? Color.FromArgb(35, 35, 55) : Color.Transparent;
    using (var b = new SolidBrush(bg)) e.Graphics.FillRectangle(b, ClientRectangle);
    if (Active) {
      using (var p = new SolidBrush(Accent)) e.Graphics.FillRectangle(p, 0, 8, 4, Height - 16);
    }
    TextRenderer.DrawText(e.Graphics, Text, Font, new Rectangle(18, 0, Width - 20, Height),
      Active ? Color.White : ForeColor, TextFormatFlags.VerticalCenter | TextFormatFlags.Left);
  }
}

public class Card : Panel {
  public int Radius = 12;
  public Card() { DoubleBuffered = true; BackColor = Color.FromArgb(22, 22, 36); }
  protected override void OnPaint(PaintEventArgs e) {
    e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
    using (var path = RoundRect(ClientRectangle, Radius))
    using (var b = new SolidBrush(BackColor)) e.Graphics.FillPath(b, path);
  }
  static GraphicsPath RoundRect(Rectangle r, int rad) {
    var p = new GraphicsPath(); int d = rad * 2;
    p.AddArc(r.X, r.Y, d, d, 180, 90); p.AddArc(r.Right - d - 1, r.Y, d, d, 270, 90);
    p.AddArc(r.Right - d - 1, r.Bottom - d - 1, d, d, 0, 90); p.AddArc(r.X, r.Bottom - d - 1, d, d, 90, 90);
    p.CloseFigure(); return p;
  }
}

public class ModernButton : Button {
  public Color NormalColor = Color.FromArgb(79, 70, 229);
  public Color HoverColor = Color.FromArgb(99, 102, 241);
  public Color PressColor = Color.FromArgb(67, 56, 202);
  bool hover = false, press = false;
  public ModernButton() {
    FlatStyle = FlatStyle.Flat; FlatAppearance.BorderSize = 0;
    ForeColor = Color.White; Font = new Font("Segoe UI Semibold", 9.5f);
    Cursor = Cursors.Hand; BackColor = NormalColor;
  }
  protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
  protected override void OnMouseLeave(EventArgs e) { hover = false; press = false; Invalidate(); base.OnMouseLeave(e); }
  protected override void OnMouseDown(MouseEventArgs e) { press = true; Invalidate(); base.OnMouseDown(e); }
  protected override void OnMouseUp(MouseEventArgs e) { press = false; Invalidate(); base.OnMouseUp(e); }
  protected override void OnPaint(PaintEventArgs e) {
    e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
    Color col = press ? PressColor : (hover ? HoverColor : NormalColor);
    using (var b = new SolidBrush(col))
    using (var path = RoundRect(ClientRectangle, 8)) e.Graphics.FillPath(b, path);
    TextRenderer.DrawText(e.Graphics, Text, Font, ClientRectangle, ForeColor,
      TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
  }
  static GraphicsPath RoundRect(Rectangle r, int rad) {
    var p = new GraphicsPath(); int d = rad * 2;
    p.AddArc(r.X, r.Y, d, d, 180, 90); p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
    p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90); p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
    p.CloseFigure(); return p;
  }
}
'@

[Windows.Forms.Application]::EnableVisualStyles()
$root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path ([Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) }
$AppDir = Join-Path $env:APPDATA 'namtweaks2'; $CfgFile = Join-Path $AppDir 'config.json'
$Dir = Join-Path $env:ProgramData 'namtweaks2'; $State = Join-Path $Dir 'backup.json'
New-Item $AppDir, $Dir -ItemType Directory -Force | Out-Null

$Bg = [Drawing.Color]::FromArgb(12, 12, 20)
$Sidebar = [Drawing.Color]::FromArgb(18, 18, 30)
$Accent = [Drawing.Color]::FromArgb(99, 102, 241)
$TextMain = [Drawing.Color]::FromArgb(240, 240, 250)
$TextMute = [Drawing.Color]::FromArgb(150, 150, 170)
$Success = [Drawing.Color]::FromArgb(34, 197, 94)
$Danger = [Drawing.Color]::FromArgb(239, 68, 68)

$Conf = @{ Style = 2; Len = 10; Thick = 2; Gap = 4; X = 0; Y = 0; Color = '#00FF00'; Outline = $true; Show = $true; Kill = 'OneDrive,Spotify,Teams,Skype,Dropbox'; Auto = $false }
if (Test-Path $CfgFile) { try { (Get-Content $CfgFile -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Conf[$_.Name] = $_.Value } } catch {} }

$backup = @{}
if (Test-Path $State) { try { $o = Get-Content $State -Raw | ConvertFrom-Json; if ($o) { $o.PSObject.Properties | ForEach-Object { $backup[$_.Name] = $_.Value } } } catch {} }
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

$x = New-Object Xhair
function Apply-Cross {
  $c = $script:Conf; $x = $script:x
  $x.Style = [int]$c.Style; $x.Len = [int]$c.Len; $x.Thick = [int]$c.Thick; $x.Gap = [int]$c.Gap; $x.Outline = [bool]$c.Outline
  $x.Col = [Drawing.ColorTranslator]::FromHtml($c.Color)
  $x.Place([int]$c.X, [int]$c.Y); $x.Invalidate()
  if ($c.Show) { if (-not $x.Visible) { $x.Show() } } else { $x.Hide() }
  $c | ConvertTo-Json | Set-Content $CfgFile -Encoding UTF8
}

function Boost-Input {
  $cur = [uint32]0; [void][Native]::NtSetTimerResolution(5000, $true, [ref]$cur)
  Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'GlobalTimerResolutionRequests' 1
  Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1
  Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 10
  foreach ($n in 'MouseSpeed','MouseThreshold1','MouseThreshold2') { Set-Reg 'HKCU:\Control Panel\Mouse' $n '0' 'String' }
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
$protect = @('explorer','winlogon','csrss','svchost','dwm','lsass','services','system','smss','wininit','FortniteClient-Win64-Shipping','EasyAntiCheat','EpicGamesLauncher')
function Boost-Game {
  $n = 0
  foreach ($name in ($script:Conf.Kill -split '[,\s]+' | Where-Object { $_ -and $protect -notcontains $_ })) {
    Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object { try { $_.Kill(); $n++ } catch {} }
  }
  Get-Process -Name 'FortniteClient-Win64-Shipping' -ErrorAction SilentlyContinue | ForEach-Object { try { $_.PriorityClass = 'High' } catch {} }
  $script:status.Text = "Game boost: closed $n process(es)"; $script:status.ForeColor = $Success
}

$form = New-Object Windows.Forms.Form
$form.Text = 'namtweaks2'
$form.ClientSize = New-Object Drawing.Size(960, 640)
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.StartPosition = 'CenterScreen'
$form.BackColor = $Bg
$form.Font = New-Object Drawing.Font('Segoe UI', 9)

$side = New-Object Windows.Forms.Panel
$side.Location = New-Object Drawing.Point(0, 0)
$side.Size = New-Object Drawing.Size(210, 640)
$side.BackColor = $Sidebar
$form.Controls.Add($side)

$logo = New-Object Windows.Forms.Label
$logo.Text = 'namtweaks2'
$logo.Location = New-Object Drawing.Point(20, 22)
$logo.Size = New-Object Drawing.Size(170, 28)
$logo.ForeColor = $TextMain
$logo.Font = New-Object Drawing.Font('Segoe UI Semibold', 15)
$side.Controls.Add($logo)

$logoSub = New-Object Windows.Forms.Label
$logoSub.Text = 'Optimization Utility'
$logoSub.Location = New-Object Drawing.Point(20, 50)
$logoSub.Size = New-Object Drawing.Size(170, 18)
$logoSub.ForeColor = $TextMute
$logoSub.Font = New-Object Drawing.Font('Segoe UI', 8)
$side.Controls.Add($logoSub)

$navHome = New-Object NavBtn
$navHome.Text = '  Home'
$navHome.Location = New-Object Drawing.Point(8, 100)
$navHome.Active = $true

$navCross = New-Object NavBtn
$navCross.Text = '  Crosshair'
$navCross.Location = New-Object Drawing.Point(8, 146)

$navBoost = New-Object NavBtn
$navBoost.Text = '  Boosters'
$navBoost.Location = New-Object Drawing.Point(8, 192)

$side.Controls.Add($navHome)
$side.Controls.Add($navCross)
$side.Controls.Add($navBoost)

$status = New-Object Windows.Forms.Label
$status.Location = New-Object Drawing.Point(16, 600)
$status.Size = New-Object Drawing.Size(180, 30)
$status.Text = 'Ready'
$status.ForeColor = $TextMute
$status.Font = New-Object Drawing.Font('Segoe UI', 8)
$side.Controls.Add($status)

$content = New-Object Windows.Forms.Panel
$content.Location = New-Object Drawing.Point(210, 0)
$content.Size = New-Object Drawing.Size(750, 640)
$content.BackColor = $Bg
$form.Controls.Add($content)

$pageHome = New-Object Windows.Forms.Panel
$pageHome.Location = New-Object Drawing.Point(0, 0)
$pageHome.Size = New-Object Drawing.Size(750, 640)
$pageHome.BackColor = $Bg
$pageHome.Visible = $true
$content.Controls.Add($pageHome)

$welcome = New-Object Windows.Forms.Label
$welcome.Text = 'Welcome back to namtweaks2'
$welcome.Location = New-Object Drawing.Point(28, 24)
$welcome.Size = New-Object Drawing.Size(500, 32)
$welcome.ForeColor = $TextMain
$welcome.Font = New-Object Drawing.Font('Segoe UI Semibold', 18)
$pageHome.Controls.Add($welcome)

$welcomeSub = New-Object Windows.Forms.Label
$welcomeSub.Text = 'Performance, optimization and Fortnite tweaks - all in one.'
$welcomeSub.Location = New-Object Drawing.Point(28, 56)
$welcomeSub.Size = New-Object Drawing.Size(500, 20)
$welcomeSub.ForeColor = $TextMute
$welcomeSub.Font = New-Object Drawing.Font('Segoe UI', 9.5)
$pageHome.Controls.Add($welcomeSub)

$gaugeCard = New-Object Card
$gaugeCard.Location = New-Object Drawing.Point(28, 100)
$gaugeCard.Size = New-Object Drawing.Size(460, 190)
$pageHome.Controls.Add($gaugeCard)

$gCpu = New-Object Gauge
$gCpu.Label = 'CPU Usage'
$gCpu.Location = New-Object Drawing.Point(30, 16)

$gRam = New-Object Gauge
$gRam.Label = 'RAM Usage'
$gRam.Location = New-Object Drawing.Point(170, 16)
$gRam.Accent = [Drawing.Color]::FromArgb(139, 92, 246)

$gPing = New-Object Gauge
$gPing.Label = 'Ping (ms)'
$gPing.Location = New-Object Drawing.Point(310, 16)
$gPing.Accent = [Drawing.Color]::FromArgb(34, 197, 94)

$gaugeCard.Controls.Add($gCpu)
$gaugeCard.Controls.Add($gRam)
$gaugeCard.Controls.Add($gPing)

$actCard = New-Object Card
$actCard.Location = New-Object Drawing.Point(510, 100)
$actCard.Size = New-Object Drawing.Size(210, 190)
$pageHome.Controls.Add($actCard)

$actTitle = New-Object Windows.Forms.Label
$actTitle.Text = 'Quick Actions'
$actTitle.Location = New-Object Drawing.Point(16, 16)
$actTitle.Size = New-Object Drawing.Size(180, 22)
$actTitle.ForeColor = $TextMain
$actTitle.Font = New-Object Drawing.Font('Segoe UI Semibold', 11)
$actCard.Controls.Add($actTitle)

$btnQuickInput = New-Object ModernButton
$btnQuickInput.Text = 'Input Reducer'
$btnQuickInput.Location = New-Object Drawing.Point(16, 50)
$btnQuickInput.Size = New-Object Drawing.Size(178, 34)
$btnQuickInput.Add_Click({ Boost-Input; $script:status.Text = 'Input reducer applied'; $script:status.ForeColor = $Success })
$actCard.Controls.Add($btnQuickInput)

$btnQuickPing = New-Object ModernButton
$btnQuickPing.Text = 'Ping Stabilizer'
$btnQuickPing.Location = New-Object Drawing.Point(16, 92)
$btnQuickPing.Size = New-Object Drawing.Size(178, 34)
$btnQuickPing.Add_Click({ Boost-Ping; $script:status.Text = 'Ping stabilizer applied'; $script:status.ForeColor = $Success })
$actCard.Controls.Add($btnQuickPing)

$btnQuickGame = New-Object ModernButton
$btnQuickGame.Text = 'Game Booster'
$btnQuickGame.Location = New-Object Drawing.Point(16, 134)
$btnQuickGame.Size = New-Object Drawing.Size(178, 34)
$btnQuickGame.Add_Click({ Boost-Game })
$actCard.Controls.Add($btnQuickGame)

$info1 = New-Object Card
$info1.Location = New-Object Drawing.Point(28, 310)
$info1.Size = New-Object Drawing.Size(340, 140)
$pageHome.Controls.Add($info1)

$i1t = New-Object Windows.Forms.Label
$i1t.Text = 'Crosshair Overlay'
$i1t.Location = New-Object Drawing.Point(18, 16)
$i1t.Size = New-Object Drawing.Size(300, 22)
$i1t.ForeColor = $TextMain
$i1t.Font = New-Object Drawing.Font('Segoe UI Semibold', 11)
$info1.Controls.Add($i1t)

$i1d = New-Object Windows.Forms.Label
$i1d.Text = "Click-through always-on-top crosshair.`nStyle, color, position fully adjustable.`nSaved automatically."
$i1d.Location = New-Object Drawing.Point(18, 46)
$i1d.Size = New-Object Drawing.Size(300, 70)
$i1d.ForeColor = $TextMute
$i1d.Font = New-Object Drawing.Font('Segoe UI', 9)
$info1.Controls.Add($i1d)

$info2 = New-Object Card
$info2.Location = New-Object Drawing.Point(386, 310)
$info2.Size = New-Object Drawing.Size(334, 140)
$pageHome.Controls.Add($info2)

$i2t = New-Object Windows.Forms.Label
$i2t.Text = 'Full Optimizer'
$i2t.Location = New-Object Drawing.Point(18, 16)
$i2t.Size = New-Object Drawing.Size(300, 22)
$i2t.ForeColor = $TextMain
$i2t.Font = New-Object Drawing.Font('Segoe UI Semibold', 11)
$info2.Controls.Add($i2t)

$i2d = New-Object Windows.Forms.Label
$i2d.Text = "Power plan, Game Mode, HAGS, Nagle,`nmouse accel, Fortnite priority + more.`nEverything is fully reversible."
$i2d.Location = New-Object Drawing.Point(18, 46)
$i2d.Size = New-Object Drawing.Size(300, 70)
$i2d.ForeColor = $TextMute
$i2d.Font = New-Object Drawing.Font('Segoe UI', 9)
$info2.Controls.Add($i2d)

$btnOpenOpt = New-Object ModernButton
$btnOpenOpt.Text = 'Open full optimizer menu'
$btnOpenOpt.Location = New-Object Drawing.Point(28, 470)
$btnOpenOpt.Size = New-Object Drawing.Size(220, 38)
$btnOpenOpt.Add_Click({ Start-Process powershell -ArgumentList '-NoExit','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'namtweaks2.ps1') })
$pageHome.Controls.Add($btnOpenOpt)

$btnRevert = New-Object ModernButton
$btnRevert.Text = 'Revert ALL changes'
$btnRevert.Location = New-Object Drawing.Point(260, 470)
$btnRevert.Size = New-Object Drawing.Size(180, 38)
$btnRevert.NormalColor = [Drawing.Color]::FromArgb(127, 29, 29)
$btnRevert.HoverColor = [Drawing.Color]::FromArgb(153, 27, 27)
$btnRevert.PressColor = [Drawing.Color]::FromArgb(100, 20, 20)
$btnRevert.Add_Click({ Undo-All; $script:status.Text = 'Everything reverted. Restart Windows.'; $script:status.ForeColor = $Danger })
$pageHome.Controls.Add($btnRevert)

$pageCross = New-Object Windows.Forms.Panel
$pageCross.Location = New-Object Drawing.Point(0, 0)
$pageCross.Size = New-Object Drawing.Size(750, 640)
$pageCross.BackColor = $Bg
$pageCross.Visible = $false
$content.Controls.Add($pageCross)

$cxTitle = New-Object Windows.Forms.Label
$cxTitle.Text = 'Crosshair'
$cxTitle.Location = New-Object Drawing.Point(28, 24)
$cxTitle.Size = New-Object Drawing.Size(300, 32)
$cxTitle.ForeColor = $TextMain
$cxTitle.Font = New-Object Drawing.Font('Segoe UI Semibold', 18)
$pageCross.Controls.Add($cxTitle)

$cxCard = New-Object Card
$cxCard.Location = New-Object Drawing.Point(28, 70)
$cxCard.Size = New-Object Drawing.Size(480, 480)
$pageCross.Controls.Add($cxCard)

function MakeLabel($parent, $text, $x, $y, $w = 140) {
  $l = New-Object Windows.Forms.Label
  $l.Text = $text; $l.Location = New-Object Drawing.Point($x, $y); $l.Size = New-Object Drawing.Size($w, 22)
  $l.ForeColor = $TextMute; $l.Font = New-Object Drawing.Font('Segoe UI', 9)
  $parent.Controls.Add($l); return $l
}
function MakeNum($parent, $key, $min, $max, $x, $y) {
  $v = [Math]::Min([Math]::Max([int]$Conf[$key], $min), $max)
  $n = New-Object Windows.Forms.NumericUpDown
  $n.Minimum = $min; $n.Maximum = $max; $n.Value = $v; $n.Tag = $key
  $n.Location = New-Object Drawing.Point($x, $y); $n.Size = New-Object Drawing.Size(100, 28)
  $n.BackColor = [Drawing.Color]::FromArgb(30, 30, 48); $n.ForeColor = $TextMain; $n.BorderStyle = 'FixedSingle'
  $n.Font = New-Object Drawing.Font('Segoe UI', 10)
  $n.Add_ValueChanged({ $script:Conf[$this.Tag] = [int]$this.Value; Apply-Cross })
  $parent.Controls.Add($n); return $n
}

$yy = 24
[void](MakeLabel $cxCard 'Style' 24 $yy)
$cb = New-Object Windows.Forms.ComboBox
$cb.DropDownStyle = 'DropDownList'
$cb.Location = New-Object Drawing.Point(180, $yy)
$cb.Size = New-Object Drawing.Size(240, 28)
$cb.BackColor = [Drawing.Color]::FromArgb(30, 30, 48); $cb.ForeColor = $TextMain; $cb.FlatStyle = 'Flat'
$cb.Font = New-Object Drawing.Font('Segoe UI', 10)
[void]$cb.Items.AddRange(@('Cross', 'Dot', 'Cross + Dot'))
$cb.SelectedIndex = [int]$Conf.Style
$cb.Add_SelectedIndexChanged({ $script:Conf.Style = $this.SelectedIndex; Apply-Cross })
$cxCard.Controls.Add($cb)

$yy = 72; [void](MakeLabel $cxCard 'Length' 24 $yy); [void](MakeNum $cxCard 'Len' 1 80 180 $yy)
$yy = 114; [void](MakeLabel $cxCard 'Thickness' 24 $yy); [void](MakeNum $cxCard 'Thick' 1 12 180 $yy)
$yy = 156; [void](MakeLabel $cxCard 'Gap' 24 $yy); [void](MakeNum $cxCard 'Gap' 0 60 180 $yy)
$yy = 198; [void](MakeLabel $cxCard 'Position X' 24 $yy); $nx = MakeNum $cxCard 'X' -900 900 180 $yy
$yy = 240; [void](MakeLabel $cxCard 'Position Y' 24 $yy); $ny = MakeNum $cxCard 'Y' -900 900 180 $yy

$yy = 288
[void](MakeLabel $cxCard 'Color' 24 $yy)
$bc = New-Object Windows.Forms.Button
$bc.Text = '  Pick color  '
$bc.Location = New-Object Drawing.Point(180, $yy)
$bc.Size = New-Object Drawing.Size(130, 30)
$bc.FlatStyle = 'Flat'; $bc.FlatAppearance.BorderSize = 0
$bc.BackColor = [Drawing.ColorTranslator]::FromHtml($Conf.Color)
$bc.ForeColor = [Drawing.Color]::White; $bc.Cursor = [Windows.Forms.Cursors]::Hand
$bc.Font = New-Object Drawing.Font('Segoe UI Semibold', 9)
$bc.Add_Click({
  $d = New-Object Windows.Forms.ColorDialog
  if ($d.ShowDialog() -eq 'OK') { $script:Conf.Color = [Drawing.ColorTranslator]::ToHtml($d.Color); $this.BackColor = $d.Color; Apply-Cross }
})
$cxCard.Controls.Add($bc)

$yy = 336
$co = New-Object Windows.Forms.CheckBox
$co.Text = 'Black outline'; $co.Location = New-Object Drawing.Point(24, $yy); $co.Size = New-Object Drawing.Size(160, 26)
$co.ForeColor = $TextMain; $co.Checked = [bool]$Conf.Outline; $co.FlatStyle = 'Flat'
$co.Font = New-Object Drawing.Font('Segoe UI', 10)
$co.Add_CheckedChanged({ $script:Conf.Outline = $this.Checked; Apply-Cross })
$cxCard.Controls.Add($co)

$cs = New-Object Windows.Forms.CheckBox
$cs.Text = 'Show crosshair'; $cs.Location = New-Object Drawing.Point(200, $yy); $cs.Size = New-Object Drawing.Size(160, 26)
$cs.ForeColor = $TextMain; $cs.Checked = [bool]$Conf.Show; $cs.FlatStyle = 'Flat'
$cs.Font = New-Object Drawing.Font('Segoe UI', 10)
$cs.Add_CheckedChanged({ $script:Conf.Show = $this.Checked; Apply-Cross })
$cxCard.Controls.Add($cs)

$yy = 384
$btnCenter = New-Object ModernButton
$btnCenter.Text = 'Center (X=0, Y=0)'
$btnCenter.Location = New-Object Drawing.Point(24, $yy)
$btnCenter.Size = New-Object Drawing.Size(200, 36)
$btnCenter.Add_Click({ $script:nx.Value = 0; $script:ny.Value = 0 })
$cxCard.Controls.Add($btnCenter)

$hint = New-Object Windows.Forms.Label
$hint.Location = New-Object Drawing.Point(24, 430)
$hint.Size = New-Object Drawing.Size(430, 40)
$hint.ForeColor = $TextMute; $hint.Font = New-Object Drawing.Font('Segoe UI', 8.5)
$hint.Text = "Use arrow keys / mouse wheel on number boxes.`nFortnite must be Windowed Fullscreen."
$cxCard.Controls.Add($hint)

$pageBoost = New-Object Windows.Forms.Panel
$pageBoost.Location = New-Object Drawing.Point(0, 0)
$pageBoost.Size = New-Object Drawing.Size(750, 640)
$pageBoost.BackColor = $Bg
$pageBoost.Visible = $false
$content.Controls.Add($pageBoost)

$bTitle = New-Object Windows.Forms.Label
$bTitle.Text = 'Boosters'
$bTitle.Location = New-Object Drawing.Point(28, 24)
$bTitle.Size = New-Object Drawing.Size(300, 32)
$bTitle.ForeColor = $TextMain
$bTitle.Font = New-Object Drawing.Font('Segoe UI Semibold', 18)
$pageBoost.Controls.Add($bTitle)

$bCard = New-Object Card
$bCard.Location = New-Object Drawing.Point(28, 70)
$bCard.Size = New-Object Drawing.Size(520, 500)
$pageBoost.Controls.Add($bCard)

$by = 24
$btnBI = New-Object ModernButton
$btnBI.Text = 'Input delay reducer  -  0.5 ms timer + no mouse accel'
$btnBI.Location = New-Object Drawing.Point(24, $by)
$btnBI.Size = New-Object Drawing.Size(470, 42)
$btnBI.Add_Click({ Boost-Input; $script:status.Text = 'Input delay reducer applied'; $script:status.ForeColor = $Success })
$bCard.Controls.Add($btnBI)

$by = 80
$btnBP = New-Object ModernButton
$btnBP.Text = 'Ping stabilizer  -  Nagle off + no throttling + flush DNS'
$btnBP.Location = New-Object Drawing.Point(24, $by)
$btnBP.Size = New-Object Drawing.Size(470, 42)
$btnBP.Add_Click({ Boost-Ping; $script:status.Text = 'Ping stabilizer applied'; $script:status.ForeColor = $Success })
$bCard.Controls.Add($btnBP)

$by = 140
[void](MakeLabel $bCard 'Ping host' 24 $by 90)
$hostBox = New-Object Windows.Forms.TextBox
$hostBox.Text = '1.1.1.1'
$hostBox.Location = New-Object Drawing.Point(120, $by)
$hostBox.Size = New-Object Drawing.Size(140, 28)
$hostBox.BackColor = [Drawing.Color]::FromArgb(30, 30, 48); $hostBox.ForeColor = $TextMain; $hostBox.BorderStyle = 'FixedSingle'
$hostBox.Font = New-Object Drawing.Font('Segoe UI', 10)
$bCard.Controls.Add($hostBox)

$by = 180
$pingLbl = New-Object Windows.Forms.Label
$pingLbl.Location = New-Object Drawing.Point(24, $by)
$pingLbl.Size = New-Object Drawing.Size(470, 24)
$pingLbl.ForeColor = $Accent
$pingLbl.Font = New-Object Drawing.Font('Segoe UI Semibold', 10)
$pingLbl.Text = 'Ping: measuring...'
$bCard.Controls.Add($pingLbl)

$by = 220
[void](MakeLabel $bCard 'Close apps (comma separated)' 24 $by 300)
$by = 246
$kb = New-Object Windows.Forms.TextBox
$kb.Text = $Conf.Kill
$kb.Location = New-Object Drawing.Point(24, $by)
$kb.Size = New-Object Drawing.Size(470, 30)
$kb.BackColor = [Drawing.Color]::FromArgb(30, 30, 48); $kb.ForeColor = $TextMain; $kb.BorderStyle = 'FixedSingle'
$kb.Font = New-Object Drawing.Font('Segoe UI', 10)
$kb.Add_TextChanged({ $script:Conf.Kill = $this.Text; $script:Conf | ConvertTo-Json | Set-Content $CfgFile -Encoding UTF8 })
$bCard.Controls.Add($kb)

$by = 294
$btnBG = New-Object ModernButton
$btnBG.Text = 'Game booster  -  close apps + Fortnite High priority'
$btnBG.Location = New-Object Drawing.Point(24, $by)
$btnBG.Size = New-Object Drawing.Size(470, 42)
$btnBG.Add_Click({ Boost-Game })
$bCard.Controls.Add($btnBG)

$by = 350
$ca = New-Object Windows.Forms.CheckBox
$ca.Text = 'Auto-boost when Fortnite starts'
$ca.Location = New-Object Drawing.Point(24, $by)
$ca.Size = New-Object Drawing.Size(300, 26)
$ca.ForeColor = $TextMain; $ca.Checked = [bool]$Conf.Auto; $ca.FlatStyle = 'Flat'
$ca.Font = New-Object Drawing.Font('Segoe UI', 10)
$ca.Add_CheckedChanged({ $script:Conf.Auto = $this.Checked; $script:Conf | ConvertTo-Json | Set-Content $CfgFile -Encoding UTF8 })
$bCard.Controls.Add($ca)

$by = 400
$btnOpt = New-Object ModernButton
$btnOpt.Text = 'Open full optimizer menu (namtweaks2.ps1)'
$btnOpt.Location = New-Object Drawing.Point(24, $by)
$btnOpt.Size = New-Object Drawing.Size(470, 38)
$btnOpt.Add_Click({ Start-Process powershell -ArgumentList '-NoExit','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'namtweaks2.ps1') })
$bCard.Controls.Add($btnOpt)

$by = 450
$btnRev = New-Object ModernButton
$btnRev.Text = 'Revert ALL changes'
$btnRev.Location = New-Object Drawing.Point(24, $by)
$btnRev.Size = New-Object Drawing.Size(470, 38)
$btnRev.NormalColor = [Drawing.Color]::FromArgb(127, 29, 29)
$btnRev.HoverColor = [Drawing.Color]::FromArgb(153, 27, 27)
$btnRev.PressColor = [Drawing.Color]::FromArgb(100, 20, 20)
$btnRev.Add_Click({ Undo-All; $script:status.Text = 'Everything reverted.'; $script:status.ForeColor = $Danger })
$bCard.Controls.Add($btnRev)

function Show-Page($name) {
  $pageHome.Visible = ($name -eq 'home')
  $pageCross.Visible = ($name -eq 'cross')
  $pageBoost.Visible = ($name -eq 'boost')
  $navHome.Active = ($name -eq 'home')
  $navCross.Active = ($name -eq 'cross')
  $navBoost.Active = ($name -eq 'boost')
  $navHome.Invalidate(); $navCross.Invalidate(); $navBoost.Invalidate()
}
$navHome.Add_Click({ Show-Page 'home' })
$navCross.Add_Click({ Show-Page 'cross' })
$navBoost.Add_Click({ Show-Page 'boost' })

$pg = New-Object Net.NetworkInformation.Ping
$rtt = New-Object Collections.Generic.List[double]
$sent = 0; $lost = 0; $boosted = $false

function Get-CpuUsage {
  try { $c = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average; return [double]$c.Average } catch { return 0 }
}
function Get-RamUsage {
  try { $os = Get-CimInstance Win32_OperatingSystem; $used = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory; return [math]::Round(100.0 * $used / $os.TotalVisibleMemorySize, 1) } catch { return 0 }
}

$pt = New-Object Windows.Forms.Timer
$pt.Interval = 1500
$pt.Add_Tick({
  $script:gCpu.Value = Get-CpuUsage; $script:gCpu.Invalidate()
  $script:gRam.Value = Get-RamUsage; $script:gRam.Invalidate()
  $script:sent++
  try {
    $r = $script:pg.Send($script:hostBox.Text, 400)
    if ($r.Status -eq 'Success') {
      $script:rtt.Add([double]$r.RoundtripTime)
      if ($script:rtt.Count -gt 20) { $script:rtt.RemoveAt(0) }
      $script:gPing.Value = [Math]::Min(100, $r.RoundtripTime); $script:gPing.Invalidate()
    } else { $script:lost++ }
  } catch { $script:lost++ }
  if ($script:rtt.Count -gt 0) {
    $m = $script:rtt | Measure-Object -Average -Minimum -Maximum
    $avg = [math]::Round($m.Average); $range = $m.Maximum - $m.Minimum; $lossPct = [math]::Round(100.0 * $script:lost / $script:sent)
    $script:pingLbl.Text = "Ping $avg ms  |  range $range ms  |  loss $lossPct%"
  }
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
