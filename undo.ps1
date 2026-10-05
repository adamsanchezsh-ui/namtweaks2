#Requires -RunAsAdministrator
# Shortcut: reverts everything namtweaks2.ps1 changed (restores your exact original values).
& (Join-Path $PSScriptRoot 'namtweaks2.ps1') -Undo
