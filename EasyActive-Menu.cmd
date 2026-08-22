@echo off
setlocal EnableExtensions

set "TOOL_NAME=EasyActive by MyPC"
set "TOOL_VERSION=1.8.12"
set "LAC_ROOT=%ProgramData%\EasyActiveByMyPC"

title %TOOL_NAME%

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%EasyActive-Engine.ps1"
set "POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" (
    set "POWERSHELL=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
)

if not exist "%POWERSHELL%" (
    echo.
    echo ERROR: Windows PowerShell was not found:
    echo        %POWERSHELL%
    echo.
    pause
    exit /b 2
)

if not exist "%PS1%" (
    echo.
    echo ERROR: Cannot find PowerShell script:
    echo        %PS1%
    echo.
    pause
    exit /b 2
)

rem Use the same WindowsPrincipal check as the PowerShell engine.
rem Do NOT use "net session" here: it can fail even for administrators when
rem the Server/LanmanServer service is stopped, causing an elevation loop.
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -Command "$id=[Security.Principal.WindowsIdentity]::GetCurrent(); $p=New-Object Security.Principal.WindowsPrincipal($id); if ($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
set "ADMIN_RC=%errorlevel%"
if "%ADMIN_RC%"=="0" goto :AdminReady

echo.
echo Administrator rights are required.
echo Requesting UAC elevation...
echo.

rem Start-Process supports the RunAs verb for .cmd files on Windows.
rem Pass the target/arguments through environment variables to avoid fragile
rem nested CMD/PowerShell quote parsing.
set "EASYACTIVE_ELEVATE_TARGET=%~f0"
set "EASYACTIVE_ELEVATE_ARGS=%*"
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -Command "$target=$env:EASYACTIVE_ELEVATE_TARGET; $argsText=$env:EASYACTIVE_ELEVATE_ARGS; if ([string]::IsNullOrWhiteSpace($argsText)) { Start-Process -FilePath $target -Verb RunAs } else { Start-Process -FilePath $target -ArgumentList $argsText -Verb RunAs }"
set "UAC_RC=%errorlevel%"
if not "%UAC_RC%"=="0" goto :ElevationFailed
exit /b 0

:ElevationFailed
echo.
echo UAC elevation was cancelled or failed.
echo PowerShell exit code: %UAC_RC%
echo.
pause
exit /b 1

:AdminReady

if not "%~1"=="" (
    call :RunPowerShell %*
    goto :Done
)

call :RunPowerShell -LauncherMenu
goto :Done

:RunPowerShell
echo.
echo Running:
echo "%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
echo.
"%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
set "SCRIPT_EXIT=%errorlevel%"
echo.
echo PowerShell script exit code: %SCRIPT_EXIT%
exit /b %SCRIPT_EXIT%

:Done
set "FINAL_EXIT=%errorlevel%"
echo.
echo Done. This window will stay open so you can read the result.
echo.
echo Exit code meaning:
echo   0 = success
echo   1 = not admin
echo   2 = fatal error
echo   3 = completed with warnings
echo.
echo Logs and reports are under:
echo   %LAC_ROOT%
echo.
pause
exit /b %FINAL_EXIT%
