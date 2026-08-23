@echo off
color 0A
title Fix AIMS Local Domain Resolution
echo ==========================================================
echo   Fixing aims.local and amis.local domain resolution
echo ==========================================================
echo.
powershell -Command "Add-Content -Path 'C:\Windows\System32\drivers\etc\hosts' -Value '`n127.0.0.1 aims.local`n127.0.0.1 amis.local'"
if %errorlevel% equ 0 (
    echo.
    echo [SUCCESS] Added 127.0.0.1 aims.local to Windows hosts!
    echo.
    echo Flushing DNS cache...
    ipconfig /flushdns
    echo.
    echo NOW OPEN: https://aims.local or https://aims.local/pilot in Chrome!
) else (
    echo.
    echo [ERROR] Permission denied. 
    echo PLEASE RIGHT-CLICK THIS FILE AND SELECT 'Run as administrator'!
)
echo.
pause
