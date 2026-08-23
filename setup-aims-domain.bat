@echo off
echo ===================================================
echo   AIMS Local Domain Setup (aims.local & amis.local)
echo ===================================================
echo.
echo Adding 127.0.0.1 aims.local and amis.local to Windows hosts file...
echo.
powershell -Command "Add-Content -Path 'C:\Windows\System32\drivers\etc\hosts' -Value '`n127.0.0.1 aims.local`n127.0.0.1 amis.local'"
if %errorlevel% equ 0 (
    echo.
    echo [SUCCESS] Domain aims.local and amis.local mapped successfully!
    echo You can now open https://aims.local or https://amis.local in your browser.
) else (
    echo.
    echo [ERROR] Failed to edit hosts file. Please right-click this file and select 'Run as administrator'.
)
echo.
pause
