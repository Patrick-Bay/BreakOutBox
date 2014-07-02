@echo off
set PAUSE_ERRORS=1
call bat\SetupSDK.bat
call bat\SetupApplication.bat

::Creates .air
::set AIR_TARGET=
::Creates .exe
set AIR_TARGET=-captive-runtime
set OPTIONS=-tsa none
call bat\Packager.bat

pause