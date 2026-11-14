@echo off
rem tstamp-a for CMD: turns global tracking on, then puts this window in a tracked session.
rem "tstamp-a stop" only stops tracking. Nothing on the computer is changed.
call "%~dp0tstamp.cmd" global-on %*
if errorlevel 1 exit /b %ERRORLEVEL%
if /i "%~1"=="stop" exit /b 0
if defined TSTAMP_CMD_SESSION exit /b 0
call "%~dp0tstamp.cmd" cmd
exit /b %ERRORLEVEL%
