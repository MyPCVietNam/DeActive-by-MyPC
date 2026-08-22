@echo off
setlocal EnableExtensions
chcp 65001 >nul 2>&1
title EasyActive by MyPC - Startup Diagnostic

echo ============================================================
echo EasyActive by MyPC - Startup Diagnostic
echo ============================================================
echo.
echo This diagnostic is READ-ONLY. It does not change activation.
echo.

echo [1] Launcher folder:
echo     %~dp0
echo.

echo [2] Required files:
if exist "%~dp0EasyActive-by-MyPC.bat" (echo     BAT : OK) else (echo     BAT : MISSING)
if exist "%~dp0EasyActive-Menu.cmd"    (echo     CMD : OK) else (echo     CMD : MISSING)
if exist "%~dp0EasyActive-Engine.ps1"  (echo     PS1 : OK) else (echo     PS1 : MISSING)
echo.

set "POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "POWERSHELL=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

echo [3] Windows PowerShell:
echo     %POWERSHELL%
if not exist "%POWERSHELL%" (
    echo     STATUS: MISSING
    goto :Done
)
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -Command "Write-Host ('    Version: ' + $PSVersionTable.PSVersion.ToString()); Write-Host ('    Architecture: ' + (Get-CimInstance Win32_OperatingSystem).OSArchitecture)"
echo     Exit code: %errorlevel%
echo.

echo [4] Administrator token:
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=New-Object Security.Principal.WindowsPrincipal($id); if ($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Write-Host '    ADMINISTRATOR: YES'; exit 0 } else { Write-Host '    ADMINISTRATOR: NO'; exit 1 }"
set "ADMIN_RC=%errorlevel%"
echo     Exit code: %ADMIN_RC%
echo.

echo [5] PowerShell parse check for EasyActive-Engine.ps1:
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -Command "$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseFile('%~dp0EasyActive-Engine.ps1',[ref]$tokens,[ref]$errors); if($errors.Count -eq 0){Write-Host '    PARSE: PASS'; exit 0}else{Write-Host '    PARSE: FAIL'; foreach($e in $errors){ Write-Host ('    ' + $e.Message + ' @ ' + $e.Extent.StartLineNumber + ':' + $e.Extent.StartColumnNumber) }; exit 2}"
set "PARSE_RC=%errorlevel%"
echo     Exit code: %PARSE_RC%
echo.

:Done
echo ============================================================
echo Diagnostic complete. This window will NOT close automatically.
echo Please take a photo/screenshot of this window if any item failed.
echo ============================================================
echo.
pause
exit /b 0
