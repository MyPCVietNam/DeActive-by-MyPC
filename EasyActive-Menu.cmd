@echo off
setlocal EnableExtensions
set "TOOL_NAME=EasyActive by MyPC"
set "TOOL_VERSION=1.8.12"
set "LAC_ROOT=%ProgramData%\EasyActiveByMyPC"

title %TOOL_NAME%

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%EasyActive-Engine.ps1"
set "POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "POWERSHELL=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

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
    echo        ^(Antivirus may have quarantined it - check the quarantine.^)
    echo.
    pause
    exit /b 2
)

REM --- Reliable elevation check via integrity-level SID. "net session" depends on the Server
REM --- (LanmanServer) service and can wrongly report "not admin" even when elevated, which then
REM --- triggers an endless UAC re-spawn / flashing window. The High/System integrity SID is
REM --- language-independent and only present when the process is actually elevated.
set "IS_ELEVATED="
whoami /groups 2>nul | find "S-1-16-12288" >nul 2>&1 && set "IS_ELEVATED=1"
if not defined IS_ELEVATED whoami /groups 2>nul | find "S-1-16-16384" >nul 2>&1 && set "IS_ELEVATED=1"

if defined IS_ELEVATED goto :Elevated

echo.
echo Administrator rights are required. Requesting UAC elevation...
echo.
if "%~1"=="" (
    "%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
) else (
    "%POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
)
set "UAC_RC=%errorlevel%"
if not "%UAC_RC%"=="0" (
    echo.
    echo UAC elevation was cancelled or failed.
    echo.
    pause
    exit /b 1
)
exit /b 0

:Elevated
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
