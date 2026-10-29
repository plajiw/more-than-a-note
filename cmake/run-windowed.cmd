@echo off
rem Used by the gallery and evidence targets on Windows (CMakeLists.txt).
rem CMake starts programs with a hidden window, and Qt obeys that on its first
rem window. "start" gives the program a normal window; pass /B first for a
rem console program so its output stays here. The exit code is passed on.
start "more than a note" /WAIT %*
exit /b %errorlevel%
