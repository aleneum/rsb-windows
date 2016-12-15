@ECHO OFF

rem MsBuild.exe [Path to your solution(*.sln)] /t:Build /p:Configuration=Release /p:TargetFramework=v4.0

rem Test if cmake and git are installed
rem WHERE cmake >nul 2>nul
rem IF %ERRORLEVEL% NEQ 0 (
rem 	ECHO Could not find cmake. Is it installed?
rem 	EXIT 1 
rem )

rem WHERE git >nul 2>nul
rem IF %ERRORLEVEL% NEQ 0 (
rem 	ECHO Could not find git. Is it installed?
rem 	EXIT 1 
rem )

rem WHERE 7z >nul 2>nul
rem IF %ERRORLEVEL% NEQ 0 (
rem 	ECHO Could not find 7z. Is it installed?
rem 	EXIT 1 
rem )

SET arch=%1
SET msvc=%2
SET target=%3

if not %target% (
	SET target=Release
)

rem Check Visual Studio Version

IF "%msvc%" == "14" (
	SET "generator=Visual Studio 14 2015"
	goto msvcEnd
)

IF "%msvc%" == "12" (
	SET "generator=Visual Studio 12 2013"
	goto msvcEnd
)

IF "%msvc%" == "11" (
	SET "generator=Visual Studio 11 2012"
	goto msvcEnd
)

IF "%MSVC%" == "10" (
	SET "generator=Visual Studio 10 2010"
	goto msvcEnd
)

:msvcEnd

if "%arch%" == "x64" (
	set generator="%generator% x64"
	set bits=64
) ELSE (
	set bits=32
)

ECHO Build RSX 0.15 for %arch% using %generator%

set target_path=build\%arch%\%target%\msvc%msvc%
set absolute_path=%cd%\%target_path%

ECHO mdkir %target_path%
ECHO mdkir %target_path%\include
ECHO mdkir %target_path%\lib
ECHO mdkir %target_path%\bin

ECHO 7zip spread.7z
ECHO cp spread\include\* %target_path%\include\
ECHO cp spread\bin\Win32\*.exe  %target_path%\bin\
ECHO cp spread\doc\sample.spread.conf %target_path%\bin\spread.conf

ECHO bitsadmin.exe /transfer "Downloading Boost" https://sourceforge.net/projects/boost/files/boost-binaries/1.62.0/boost_1_62_0-msvc-%msvc%.0-%bits%.exe/download boost.exe
ECHO 7z e boost.exe

rem TODO: build protobuf

ECHO cd protobuf\vsprojects
ECHO msbuild /tv:%msvc%.0 /p:Configuration=%target% protobuf.sln
ECHO extract_includes.bat
ECHO cp include\* %absolute_path%\include\
rem Copy lirabries %absolute_path%\lib\

for %%p in (rsc, rsb-protocol, rsb-cpp, rsb-spread) do (
	ECHO Building %%p ...
	ECHO cd %%p
	ECHO mkdir build
	ECHO cd build
	ECHO cmake -DCMAKE_INSTALL_PREFIX=%absolute_path% ..
	ECHO msbuild.exe ALL.vcxproj /tv:%msvc%.0 /p:Configuration=%target%
	ECHO msbuild.exe INSTALL.vcxproj /tv:%msvc%.0 /p:Configuration=%target%
	ECHO cd ../..
)