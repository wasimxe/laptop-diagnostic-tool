@echo off
REM Laptop Diagnostic Tool v15.0 Launcher
REM Developed by Tanxe Studio

echo ============================================================
echo   LAPTOP DIAGNOSTIC TOOL v15.0 LAUNCHER
echo   Developed by Tanxe Studio
echo ============================================================
echo.
echo Starting diagnostic tool...
echo.

REM Run the PowerShell script with execution policy bypass
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0FinalDiagnostic_v15.ps1"

echo.
echo Launcher complete. You can close this window.
pause
