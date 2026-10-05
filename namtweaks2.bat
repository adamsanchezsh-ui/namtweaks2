@echo off
rem namtweaks2 launcher - double-click, accept the admin prompt
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File ''%~dp0namtweaks2-app.ps1'''"
