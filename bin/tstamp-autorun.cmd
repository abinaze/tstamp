@echo off
rem TStamp AutoRun for Command Prompt. Only used when the installer box
rem "Command Prompt: start a TStamp session in new windows" was ticked.
rem Windows runs this each time cmd.exe starts. It does nothing unless this is
rem an interactive window and global tracking is on (tstamp-a).
if defined TSTAMP_CMD_SESSION goto :eof
if defined TSTAMP_NO_AUTORUN goto :eof
rem Skip "cmd /c ..." and "cmd /r ..." (scripts and other programs).
set "TSA_L=%cmdcmdline:"=%"
set "TSA_M=%TSA_L:/c=%"
if not "%TSA_M%"=="%TSA_L%" goto done
set "TSA_M=%TSA_L:/r=%"
if not "%TSA_M%"=="%TSA_L%" goto done
set "TSA_H=%TSTAMP_HOME%"
if not defined TSA_H set "TSA_H=%USERPROFILE%\.tstamp"
if not exist "%TSA_H%\enabled" goto done
if not exist "%~dp0..\shells\cmdsession.ps1" goto done
set "TSA_L="
set "TSA_M="
set "TSA_H="
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0..\shells\cmdsession.ps1" -Auto
rem 0: the person typed exit in the session, so the window closes.
rem Anything else (global tracking was off, or the session could not start): keep this window.
if errorlevel 1 goto :eof
exit
:done
set "TSA_L="
set "TSA_M="
set "TSA_H="
