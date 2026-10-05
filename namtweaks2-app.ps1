#Requires -RunAsAdministrator
# namtweaks2 app - modern dark-blue UI
# crosshair overlay + input delay reducer + ping stabilizer + game booster
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
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

// Modern rounded button
public class ModernButton : Button {
  public Color NormalColor = Color.FromArgb(30, 64, 120);
  public Color HoverColor  = Color.FromArgb(37, 99, 180);
  public Color PressColor  = Color.FromArgb(25, 80, 160);
  private bool hover = false, press = false;
  public ModernButton() {
    FlatStyle = FlatStyle.Flat;
    FlatAppearance.BorderSize = 0;
    ForeColor = Color.White;
    Font = new Font("Segoe UI Semibold", 9.5f);
    Cursor = Cursors.Hand;
    BackColor = NormalColor;
  }
  protected override void OnMouseEnter(EventArgs e) { hover = true;  Invalidate(); base.OnMouseEnter(e); }
  protected override void OnMouseLeave(EventArgs e) { hover = false; press = false; Invalidate(); base.OnMouseLeave(e); }
  protected override void OnMouseDown(MouseEventArgs e) { press = true;  Invalidate(); base.OnMouseDown(e); }
  protected override void OnMouseUp(MouseEventArgs e)   { press = false; Invalidate(); base.OnMouseUp(e); }
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

# ---------- theme ----------
$Bg       = [Drawing.Color]::FromArgb(10, 14, 23)      # deep dark
$PanelBg  = [Drawing.Color]::FromArgb(18, 24, 38)      # card
$Accent   = [Drawing.Color]::FromArgb(59, 130, 246)    # blue
$Accent2  = [Drawing.Color]::FromArgb(37, 99, 235)
$TextMain = [Drawing.Color]::FromArgb(226, 232, 240)
$TextMute = [Drawing.Color]::FromArgb(148, 163, 184)
$Border   = [Drawing.Color]::FromArgb(30, 41, 59)
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

# ===================== UI =====================
$form = New-Object Windows.Forms.Form -Property @{
    Text            = 'namtweaks2'
    ClientSize     = '420,620'
    FormBorderStyle= 'FixedSingle'
    MaximizeBox    = $false
    StartPosition  = 'CenterScreen'
    BackColor      = $Bg
    Font           = New-Object Drawing.Font('Segoe UI', 9)
}
$form.Icon = [Drawing.SystemIcons]::Application

# Header
$header = New-Object Windows.Forms.Panel -Property @{
    Left = 0; Top = 0; Width = 420; Height = 64
    BackColor = $PanelBg
}
$title = New-Object Windows.Forms.Label -Property @{
    Text = 'namtweaks2'; Left = 20; Top = 12; Width = 280; Height = 28
    ForeColor = $TextMain; Font = New-Object Drawing.Font('Segoe UI Semibold', 16)
}
$subtitle = New-Object Windows.Forms.Label -Property @{
    Text = 'Fortnite tweaks • modern UI'; Left = 20; Top = 38; Width = 280; Height = 18
    ForeColor = $TextMute; Font = New-Object Drawing.Font('Segoe UI', 8.5)
}
$header.Controls.AddRange(@($title, $subtitle))
$form.Controls.Add($header)

# Accent line under header
$line = New-Object Windows.Forms.Panel -Property @{
    Left = 0; Top = 64; Width = 420; Height = 3; BackColor = $Accent
}
$form.Controls.Add($line)

# Tabs (styled)
$tabs = New-Object Windows.Forms.TabControl -Property @{
    Left = 12; Top = 78; Width = 396; Height = 500
    Font = New-Object Drawing.Font('Segoe UI Semibold', 9.5)
}
$tabs.Appearance = 'Normal'
$t1 = New-Object Windows.Forms.TabPage '  Crosshair  '
$t2 = New-Object Windows.Forms.TabPage '  Boosters  '
$t1.BackColor = $Bg; $t2.BackColor = $Bg
$t1.ForeColor = $TextMain; $t2.ForeColor = $TextMain
$tabs.TabPages.AddRange(@($t1, $t2))
$form.Controls.Add($tabs)

# Status bar
$status = New-Object Windows.Forms.Label -Property @{
    Left = 16; Top = 588; Width = 390; Height = 24
    Text = 'Ready'; ForeColor = $TextMute
    Font = New-Object Drawing.Font('Segoe UI', 8.5)
}
$form.Controls.Add($status)

# Helpers
function MakeLabel($text, $x, $y, $w = 130) {
    New-Object Windows.Forms.Label -Property @{
        Text = $text; Left = $x; Top = $y; Width = $w; Height = 22
        ForeColor = $TextMute; Font = New-Object Drawing.Font('Segoe UI', 9)
    }
}
function MakeNum($key, $min, $max, $x, $y) {
    $v = [Math]::Min([Math]::Max([int]$Conf[$key], $min), $max)
    $n = New-Object Windows.Forms.NumericUpDown -Property @{
        Minimum = $min; Maximum = $max; Value = $v; Tag = $key
        Left = $x; Top = $y; Width = 90; Height = 26
        BackColor = $PanelBg; ForeColor = $TextMain; BorderStyle = 'FixedSingle'
        Font = New-Object Drawing.Font('Segoe UI', 9.5)
    }
    $n.add_ValueChanged({ $script:Conf[$this.Tag] = [int]$this.Value; Apply-Cross })
    $n
}
function MakeBtn($text, $x, $y, $w, $h, $fn, $danger = $false) {
    $b = New-Object ModernButton
    $b.Text = $text; $b.Left = $x; $b.Top = $y; $b.Width = $w; $b.Height = $h
    if ($danger) {
        $b.NormalColor = [Drawing.Color]::FromArgb(127, 29, 29)
        $b.HoverColor  = [Drawing.Color]::FromArgb(153, 27, 27)
        $b.PressColor  = [Drawing.Color]::FromArgb(100, 20, 20)
    }
    $b.add_Click($fn)
    $b
}

# ========== CROSSHAIR TAB ==========
$y = 18
$t1.Controls.Add((MakeLabel 'Style' 20 $y))
$cb = New-Object Windows.Forms.ComboBox -Property @{
    DropDownStyle = 'DropDownList'; Left = 150; Top = $y; Width = 210; Height = 28
    BackColor = $PanelBg; ForeColor = $TextMain; FlatStyle = 'Flat'
    Font = New-Object Drawing.Font('Segoe UI', 9.5)
}
[void]$cb.Items.AddRange(@('Cross', 'Dot', 'Cross + Dot'))
$cb.SelectedIndex = [int]$Conf.Style
$cb.add_SelectedIndexChanged({ $script:Conf.Style = $this.SelectedIndex; Apply-Cross })
$t1.Controls.Add($cb)
$y += 42

$t1.Controls.Add((MakeLabel 'Length' 20 $y))
$t1.Controls.Add((MakeNum 'Len' 1 80 150 $y))
$y += 38
$t1.Controls.Add((MakeLabel 'Thickness' 20 $y))
$t1.Controls.Add((MakeNum 'Thick' 1 12 150 $y))
$y += 38
$t1.Controls.Add((MakeLabel 'Gap' 20 $y))
$t1.Controls.Add((MakeNum 'Gap' 0 60 150 $y))
$y += 38
$t1.Controls.Add((MakeLabel 'Position X' 20 $y))
$nx = MakeNum 'X' -900 900 150 $y; $t1.Controls.Add($nx)
$y += 38
$t1.Controls.Add((MakeLabel 'Position Y' 20 $y))
$ny = MakeNum 'Y' -900 900 150 $y; $t1.Controls.Add($ny)
$y += 42

$t1.Controls.Add((MakeLabel 'Color' 20 $y))
$bc = New-Object Windows.Forms.Button -Property @{
    Text = '  Pick color  '; Left = 150; Top = $y; Width = 120; Height = 28
    FlatStyle = 'Flat'; FlatAppearance = @{ BorderSize = 0 }
    BackColor = [Drawing.ColorTranslator]::FromHtml($Conf.Color)
    ForeColor = [Drawing.Color]::White; Cursor = [Windows.Forms.Cursors]::Hand
    Font = New-Object Drawing.Font('Segoe UI Semibold', 9)
}
$bc.add_Click({
    $d = New-Object Windows.Forms.ColorDialog
    if ($d.ShowDialog() -eq 'OK') {
        $script:Conf.Color = [Drawing.ColorTranslator]::ToHtml($d.Color)
        $this.BackColor = $d.Color
        Apply-Cross
    }
})
$t1.Controls.Add($bc)
$y += 42

$co = New-Object Windows.Forms.CheckBox -Property @{
    Text = 'Black outline'; Left = 20; Top = $y; Width = 160; Height = 24
    ForeColor = $TextMain; Checked = [bool]$Conf.Outline
    FlatStyle = 'Flat'; Font = New-Object Drawing.Font('Segoe UI', 9.5)
}
$co.add_CheckedChanged({ $script:Conf.Outline = $this.Checked; Apply-Cross })
$t1.Controls.Add($co)

$cs = New-Object Windows.Forms.CheckBox -Property @{
    Text = 'Show crosshair'; Left = 200; Top = $y; Width = 160; Height = 24
    ForeColor = $TextMain; Checked = [bool]$Conf.Show
    FlatStyle = 'Flat'; Font = New-Object Drawing.Font('Segoe UI', 9.5)
}
$cs.add_CheckedChanged({ $script:Conf.Show = $this.Checked; Apply-Cross })
$t1.Controls.Add($cs)
$y += 40

$t1.Controls.Add((MakeBtn 'Center crosshair (X=0, Y=0)' 20 $y 360 36 {
    $script:nx.Value = 0; $script:ny.Value = 0
}))
$y += 50

$hint = New-Object Windows.Forms.Label -Property @{
    Left = 20; Top = $y; Width = 360; Height = 80
    ForeColor = $TextMute; Font = New-Object Drawing.Font('Segoe UI', 8.5)
    Text = "Tip: click a number box and use arrow keys / mouse wheel to nudge the crosshair pixel by pixel.`nFortnite must run in Windowed Fullscreen, otherwise the overlay is hidden.`nSettings are saved automatically."
}
$t1.Controls.Add($hint)

# ========== BOOSTERS TAB ==========
$y = 18
$t2.Controls.Add((MakeBtn 'Input delay reducer  •  0.5 ms timer + no mouse accel' 20 $y 360 40 {
    Boost-Input
    $script:status.Text = 'Input delay reducer applied (active while app is open)'
    $script:status.ForeColor = $Success
}))
$y += 52

$t2.Controls.Add((MakeBtn 'Ping stabilizer  •  Nagle off + no throttling + flush DNS' 20 $y 360 40 {
    Boost-Ping
    $script:status.Text = 'Ping stabilizer applied'
    $script:status.ForeColor = $Success
}))
$y += 56

$t2.Controls.Add((MakeLabel 'Ping host' 20 $y 80))
$hostBox = New-Object Windows.Forms.TextBox -Property @{
    Text = '1.1.1.1'; Left = 110; Top = $y; Width = 140; Height = 26
    BackColor = $PanelBg; ForeColor = $TextMain; BorderStyle = 'FixedSingle'
    Font = New-Object Drawing.Font('Segoe UI', 9.5)
}
$t2.Controls.Add($hostBox)
$y += 36

$pingLbl = New-Object Windows.Forms.Label -Property @{
    Left = 20; Top = $y; Width = 360; Height = 22
    ForeColor = $Accent; Font = New-Object Drawing.Font('Segoe UI Semibold', 9.5)
    Text = 'Ping: measuring...'
}
$t2.Controls.Add($pingLbl)
$y += 36

$t2.Controls.Add((MakeLabel 'Close apps (comma separated)' 20 $y 260))
$y += 24
$kb = New-Object Windows.Forms.TextBox -Property @{
    Text = $Conf.Kill; Left = 20; Top = $y; Width = 360; Height = 28
    BackColor = $PanelBg; ForeColor = $TextMain; BorderStyle = 'FixedSingle'
    Font = New-Object Drawing.Font('Segoe UI', 9.5)
}
$kb.add_TextChanged({ $script:Conf.Kill = $this.Text; $script:Conf | ConvertTo-Json | Set-Content $CfgFile })
$t2.Controls.Add($kb)
$y += 40

$t2.Controls.Add((MakeBtn 'Game booster  •  close apps + Fortnite High priority' 20 $y 360 40 {
    Boost-Game
}))
$y += 48

$ca = New-Object Windows.Forms.CheckBox -Property @{
    Text = 'Auto-boost when Fortnite starts'; Left = 20; Top = $y; Width = 280; Height = 24
    ForeColor = $TextMain; Checked = [bool]$Conf.Auto
    FlatStyle = 'Flat'; Font = New-Object Drawing.Font('Segoe UI', 9.5)
}
$ca.add_CheckedChanged({ $script:Conf.Auto = $this.Checked; $script:Conf | ConvertTo-Json | Set-Content $CfgFile })
$t2.Controls.Add($ca)
$y += 40

$t2.Controls.Add((MakeBtn 'Open full optimizer menu (namtweaks2.ps1)' 20 $y 360 36 {
    Start-Process powershell -ArgumentList '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $root 'namtweaks2.ps1')
}))
$y += 48

$t2.Controls.Add((MakeBtn 'Revert ALL changes (boosters + optimizer)' 20 $y 360 36 {
    Undo-All
    $script:status.Text = 'Everything reverted. Restart Windows recommended.'
    $script:status.ForeColor = $Danger
} $true))

# live ping + auto-boost
$pg = New-Object Net.NetworkInformation.Ping
$rtt = New-Object Collections.Generic.List[double]
$sent = 0; $lost = 0; $boosted = $false
$pt = New-Object Windows.Forms.Timer -Property @{ Interval = 1000 }
$pt.add_Tick({
    $script:sent++
    try {
        $r = $script:pg.Send($script:hostBox.Text, 400)
        if ($r.Status -eq 'Success') {
            $script:rtt.Add([double]$r.RoundtripTime)
            if ($script:rtt.Count -gt 30) { $script:rtt.RemoveAt(0) }
        } else { $script:lost++ }
    } catch { $script:lost++ }
    if ($script:rtt.Count) {
        $m = $script:rtt | Measure-Object -Average -Minimum -Maximum
        $script:pingLbl.Text = ("Ping {0} ms  •  range {1} ms  •  loss {2}%" -f `
            [math]::Round($m.Average), ($m.Maximum - $m.Minimum), [math]::Round(100 * $script:lost / $script:sent))
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
