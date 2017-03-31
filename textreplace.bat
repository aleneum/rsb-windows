@echo off 

rem http://stackoverflow.com/a/23076141
setlocal enableextensions disabledelayedexpansion

set "search=%2"
set "replace=%3"
set "textFile=%1"

for /f "delims=" %%i in ('type "%textFile%" ^& break ^> "%textFile%" ') do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    >>"%textFile%" echo(!line:%search%=%replace%!
    endlocal
)