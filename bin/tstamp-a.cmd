@echo off
rem tstamp-a for CMD: turns global tracking on for bash and PowerShell windows.
call "%~dp0tstamp.cmd" global-on %*
exit /b %ERRORLEVEL%
