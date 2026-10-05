#Requires -RunAsAdministrator
# namtweaks2 - modern EMTweaks-style dark UI
# TEMP: simple working version while full UI is fixed
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object Windows.Forms.Form
$form.Text = 'namtweaks2'
$form.Size = New-Object Drawing.Size(500, 400)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [Drawing.Color]::FromArgb(20, 20, 30)

$lbl = New-Object Windows.Forms.Label
$lbl.Text = 'namtweaks2 loaded successfully!`n`nFull modern UI is being restored.`nYou can still use the tweak script.'
$lbl.ForeColor = [Drawing.Color]::White
$lbl.Font = New-Object Drawing.Font('Segoe UI', 12)
$lbl.Location = New-Object Drawing.Point(30, 40)
$lbl.Size = New-Object Drawing.Size(420, 120)
$form.Controls.Add($lbl)

$btn = New-Object Windows.Forms.Button
$btn.Text = 'Open tweak menu (namtweaks2.ps1)'
$btn.Location = New-Object Drawing.Point(30, 180)
$btn.Size = New-Object Drawing.Size(300, 40)
$btn.Add_Click({
  $root = if ($PSScriptRoot) { $PSScriptRoot } else { $env:TEMP }
  $script = Join-Path $root 'namtweaks2.ps1'
  if (Test-Path $script) {
    Start-Process powershell -ArgumentList '-NoExit','-ExecutionPolicy','Bypass','-File',$script
  } else {
    [Windows.Forms.MessageBox]::Show('namtweaks2.ps1 not found next to this file')
  }
})
$form.Controls.Add($btn)

$btn2 = New-Object Windows.Forms.Button
$btn2.Text = 'Close'
$btn2.Location = New-Object Drawing.Point(30, 240)
$btn2.Size = New-Object Drawing.Size(120, 35)
$btn2.Add_Click({ $form.Close() })
$form.Controls.Add($btn2)

[void]$form.ShowDialog()
