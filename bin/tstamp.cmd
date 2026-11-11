@echo off
rem tstamp for CMD: runs the normal tstamp commands through Git Bash.
rem "tstamp" with no arguments starts a tracked session; "tstamp run COMMAND" times one command.
setlocal
if "%~1"=="" goto session
if /i "%~1"=="cmd" goto session
set "BASH_EXE="
if defined TSTAMP_BASH set "BASH_EXE=%TSTAMP_BASH%"
if not defined BASH_EXE if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH_EXE if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" set "BASH_EXE=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not defined BASH_EXE if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not defined BASH_EXE goto nobash
if not exist "%BASH_EXE%" goto nobash
set "TSTAMP_SCRIPT=%~dp0tstamp"
set "TSTAMP_SCRIPT=%TSTAMP_SCRIPT:\=/%"
set "MSYS2_ARG_CONV_EXCL=*"
set "TSTAMP_RUN_SHELL=cmd"
"%BASH_EXE%" "%TSTAMP_SCRIPT%" %*
exit /b %ERRORLEVEL%
:nobash
echo tstamp: Git Bash was not found. Install Git for Windows: https://git-scm.com/download/win 1>&2
exit /b 1
:session
if not exist "%~dp0..\shells\cmdsession.ps1" goto nosession
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0..\shells\cmdsession.ps1" %2
exit /b %ERRORLEVEL%
:nosession
echo tstamp: the session script was not found. 1>&2
exit /b 1
