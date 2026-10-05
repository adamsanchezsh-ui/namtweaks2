#Requires -RunAsAdministrator
# namtweaks2 app - crosshair overlay + input delay reducer + ping stabilizer + game booster
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
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
'@
[Windows.Forms.Application]::EnableVisualStyles()
$root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path ([Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) }
$AppDir = Join-Path $env:APPDATA 'namtweaks2'; $CfgFile = Join-Path $AppDir 'config.json'
$Dir = Join-Path $env:ProgramData 'namtweaks2'; $State = Join-Path $Dir 'backup.json'
New-Item $AppDir, $Dir -ItemType Directory -Force | Out-Null

$Conf = @{ Style = 2; Len = 10; Thick = 2; Gap = 4; X = 0; Y = 0; Color = '#00FF00'; Outline = $true; Show = $true; Kill = 'OneDrive,Spotify,Teams,Skype,Dropbox'; Auto = $false }
if (Test-Path $CfgFile) { (Get-Content $CfgFile -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Conf[$_.Name] = $_.Value } }

# same backup file as namtweaks2.ps1, so -Undo there reverts these too
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
    $cur = [uint32]0; [void][Native]::NtSetTimerResolution(5000, $true, [ref]$cur)   # 0.5 ms timer while app runs
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
    $script:status.Text = 'Game boost: closed ' + $n + ' process(es), Fortnite set to High priority'
}

# ---------------- UI ----------------
$form = New-Object Windows.Forms.Form -Property @{ Text = 'namtweaks2'; ClientSize = '360,500'; FormBorderStyle = 'FixedSingle'; MaximizeBox = $false; StartPosition = 'CenterScreen' }
$tabs = New-Object Windows.Forms.TabControl -Property @{ Left = 0; Top = 0; Width = 360; Height = 470 }
$t1 = New-Object Windows.Forms.TabPage 'Crosshair'; $t2 = New-Object Windows.Forms.TabPage 'Boosters'
$tabs.TabPages.AddRange(@($t1, $t2))
$status = New-Object Windows.Forms.Label -Property @{ Left = 8; Top = 474; Width = 345; Height = 20; Text = 'Ready' }
$form.Controls.AddRange(@($tabs, $status))
$script:y = 12
function Row($page, $text, $ctl) {
    $l = New-Object Windows.Forms.Label -Property @{ Text = $text; Left = 12; Top = $script:y + 4; Width = 110 }
    $ctl.Left = 130; $ctl.Top = $script:y; $ctl.Width = 200; $page.Controls.AddRange(@($l, $ctl)); $script:y += 32
}
function Btn($page, $text, $fn) {
    $b = New-Object Windows.Forms.Button -Property @{ Text = $text; Left = 12; Top = $script:y; Width = 320; Height = 28 }
    $b.add_Click($fn); $page.Controls.Add($b); $script:y += 34
}
function Num($key, $min, $max) {
    $v = [Math]::Min([Math]::Max([int]$Conf[$key], $min), $max)
    $n = New-Object Windows.Forms.NumericUpDown -Property @{ Minimum = $min; Maximum = $max; Value = $v; Tag = $key }
    $n.add_ValueChanged({ $script:Conf[$this.Tag] = [int]$this.Value; Apply-Cross }); $n
}

$cb = New-Object Windows.Forms.ComboBox -Property @{ DropDownStyle = 'DropDownList' }
[void]$cb.Items.AddRange(@('Cross', 'Dot', 'Cross + dot')); $cb.SelectedIndex = [int]$Conf.Style
$cb.add_SelectedIndexChanged({ $script:Conf.Style = $this.SelectedIndex; Apply-Cross })
Row $t1 'Style' $cb
Row $t1 'Length' (Num 'Len' 1 80)
Row $t1 'Thickness' (Num 'Thick' 1 12)
Row $t1 'Gap' (Num 'Gap' 0 60)
$nx = Num 'X' -900 900; Row $t1 'Position X (left/right)' $nx
$ny = Num 'Y' -900 900; Row $t1 'Position Y (up/down)' $ny
$bc = New-Object Windows.Forms.Button -Property @{ Text = 'Pick color'; BackColor = [Drawing.ColorTranslator]::FromHtml($Conf.Color) }
$bc.add_Click({ $d = New-Object Windows.Forms.ColorDialog; if ($d.ShowDialog() -eq 'OK') { $script:Conf.Color = [Drawing.ColorTranslator]::ToHtml($d.Color); $this.BackColor = $d.Color; Apply-Cross } })
Row $t1 'Color' $bc
$co = New-Object Windows.Forms.CheckBox -Property @{ Text = 'Black outline'; Checked = [bool]$Conf.Outline }
$co.add_CheckedChanged({ $script:Conf.Outline = $this.Checked; Apply-Cross }); Row $t1 '' $co
$cs = New-Object Windows.Forms.CheckBox -Property @{ Text = 'Show crosshair'; Checked = [bool]$Conf.Show }
$cs.add_CheckedChanged({ $script:Conf.Show = $this.Checked; Apply-Cross }); Row $t1 '' $cs
Btn $t1 'Center (X=0, Y=0)' { $script:nx.Value = 0; $script:ny.Value = 0 }
$hint = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $script:y + 6; Width = 325; Height = 90; Text = 'Click a number box and use the arrow keys / mouse wheel to nudge the crosshair pixel by pixel. Fortnite must run in Windowed Fullscreen, otherwise the overlay is hidden. Settings are saved automatically.' }
$t1.Controls.Add($hint)

$script:y = 12
Btn $t2 'Input delay reducer (0.5 ms timer, no mouse accel, no power throttling)' { Boost-Input; $script:status.Text = 'Input delay reducer applied (timer stays active while this app is open)' }
Btn $t2 'Ping stabilizer (Nagle off, no network throttling, flush DNS)' { Boost-Ping; $script:status.Text = 'Ping stabilizer applied' }
$hostBox = New-Object Windows.Forms.TextBox -Property @{ Text = '1.1.1.1' }; Row $t2 'Ping host' $hostBox
$pingLbl = New-Object Windows.Forms.Label -Property @{ Left = 12; Top = $script:y; Width = 325; Height = 22; Text = 'Ping: measuring...' }; $t2.Controls.Add($pingLbl); $script:y += 32
$kb = New-Object Windows.Forms.TextBox -Property @{ Text = $Conf.Kill }
$kb.add_TextChanged({ $script:Conf.Kill = $this.Text; $script:Conf | ConvertTo-Json | Set-Content $CfgFile }); Row $t2 'Close apps' $kb
Btn $t2 'Game booster: close those apps + Fortnite High priority' { Boost-Game }
$ca = New-Object Windows.Forms.CheckBox -Property @{ Text = 'Auto-boost when Fortnite starts'; Checked = [bool]$Conf.Auto; Width = 300 }
$ca.add_CheckedChanged({ $script:Conf.Auto = $this.Checked; $script:Conf | ConvertTo-Json | Set-Content $CfgFile }); Row $t2 '' $ca
Btn $t2 'Open full optimizer menu (namtweaks2.ps1)' { Start-Process powershell -ArgumentList '-NoExit', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $root 'namtweaks2.ps1') }
Btn $t2 'Revert ALL changes (boosters + optimizer)' { Undo-All; $script:status.Text = 'Everything reverted. Restart Windows.' }

# live ping + auto-boost timers
$pg = New-Object Net.NetworkInformation.Ping; $rtt = New-Object Collections.Generic.List[double]; $sent = 0; $lost = 0; $boosted = $false
$pt = New-Object Windows.Forms.Timer -Property @{ Interval = 1000 }
$pt.add_Tick({
    $script:sent++
    try {
        $r = $script:pg.Send($script:hostBox.Text, 400)
        if ($r.Status -eq 'Success') { $script:rtt.Add([double]$r.RoundtripTime); if ($script:rtt.Count -gt 30) { $script:rtt.RemoveAt(0) } } else { $script:lost++ }
    } catch { $script:lost++ }
    if ($script:rtt.Count) {
        $m = $script:rtt | Measure-Object -Average -Minimum -Maximum
        $script:pingLbl.Text = 'Ping ' + [math]::Round($m.Average) + ' ms | range ' + ($m.Maximum - $m.Minimum) + ' ms | loss ' + [math]::Round(100 * $script:lost / $script:sent) + '%'
    }
    if ($script:Conf.Auto) {
        $f = Get-Process -Name 'FortniteClient-Win64-Shipping' -ErrorAction SilentlyContinue
        if ($f -and -not $script:boosted) { Boost-Game; $script:boosted = $true } elseif (-not $f) { $script:boosted = $false }
    }
})

Apply-Cross
$pt.Start()
[void]$form.ShowDialog()
$pt.Stop(); $x.Close()
