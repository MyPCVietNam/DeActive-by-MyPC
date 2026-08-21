@echo off
setlocal EnableExtensions
title EasyActive DIAGNOSE (read-only, stays open)
set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%EasyActive-Engine.ps1"
set "CMD=%SCRIPT_DIR%EasyActive-Menu.cmd"
set "BAT=%SCRIPT_DIR%EasyActive-by-MyPC.bat"
set "POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "POWERSHELL=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

echo ==================================================
echo   EasyActive DIAGNOSE - checks only, never changes
echo   Windows/Office. This window stays open (pause).
echo ==================================================
echo.

echo [Files]
if exist "%BAT%" (echo   BAT : OK) else (echo   BAT : MISSING)
if exist "%CMD%" (echo   CMD : OK) else (echo   CMD : MISSING)
if exist "%PS1%" (echo   PS1 : OK) else (echo   PS1 : MISSING  ^<-- antivirus may have quarantined it)
if exist "%POWERSHELL%" (echo   PowerShell.exe : OK) else (echo   PowerShell.exe : MISSING)
echo.

if not exist "%PS1%" goto :End
if not exist "%POWERSHELL%" goto :End

echo [PowerShell version]
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -Command "$PSVersionTable.PSVersion.ToString()"
echo.

echo [Elevation]
set "IS_ELEVATED=NO"
whoami /groups 2>nul | find "S-1-16-12288" >nul 2>&1 && set "IS_ELEVATED=YES"
if "%IS_ELEVATED%"=="NO" whoami /groups 2>nul | find "S-1-16-16384" >nul 2>&1 && set "IS_ELEVATED=YES"
echo   Running as Administrator: %IS_ELEVATED%
echo.

echo [Parse check of EasyActive-Engine.ps1]
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -Command "$errs=$null; [void][System.Management.Automation.Language.Parser]::ParseFile('%PS1%',[ref]$null,[ref]$errs); if ($errs -and $errs.Count -gt 0) { Write-Host ('  PARSE: FAIL - {0} error(s):' -f $errs.Count) -ForegroundColor Red; $errs | ForEach-Object { Write-Host ('    {0} @ line {1}, col {2}' -f $_.Message, $_.Extent.StartLineNumber, $_.Extent.StartColumnNumber) -ForegroundColor Yellow } } else { Write-Host '  PARSE: OK - no syntax errors.' -ForegroundColor Green }"
echo.

:End
echo --------------------------------------------------
echo Diagnose finished. If PARSE says FAIL, screenshot the
echo yellow lines and send them. If everything is OK here but
echo the normal launcher still flashes, the cause is the
echo Windows environment (AV, .cmd association, AutoRun, policy).
echo --------------------------------------------------
echo.
pause
exit /b 0
