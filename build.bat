rem @ECHO OFF

rem MsBuild.exe [Path to your solution(*.sln)] /t:Build /p:Configuration=Release /p:TargetFramework=v4.0

SET arch=%1
SET msvc=%2
SET target=%3
SET rst=%4

set boost_version=boost-1.62.0
set protobuf_version=
set rsx_version=0.15

set PATH=%PATH%;C:\Program Files (x86)\MSBuild\%msvc%.0\Bin
set PATH=%PATH%;C:\Program Files (x86)\Microsoft Visual Studio %msvc%.0\Common7\IDE

WHERE msbuild >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
	ECHO Could not find proper msbuild. Is it installed?
 	EXIT 1 
)

WHERE devenv.exe >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
	ECHO Could not find Visual Studio IDE. Is it installed?
 	EXIT 1 
)

rem Test if cmake and git are installed
WHERE cmake >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
	ECHO Could not find cmake. Is it installed?
 	EXIT 1 
)

WHERE git >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
	ECHO Could not find git. Is it installed?
	EXIT 1 
)

if [%target%] == [] (
	SET target=Release
)

if "%target%" == "Release" (
	set lower_target="release"
) else (
	set lower_target="debug"
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

IF "%msvc%" == "10" (
	SET "generator=Visual Studio 10 2010"
	goto msvcEnd
)

:msvcEnd

IF "%arch%" == "x64" (
	set generator="%generator% Win64"
	set bits=64
) ELSE (
	set bits=32
)

ECHO Build RSX 0.15 for %arch% using %generator%

set target_path=build\%arch%\%target%\msvc%msvc%
set absolute_path=%cd%\%target_path%

IF NOT EXIST %target_path% (
	mkdir %target_path%
	mkdir %target_path%\include
	mkdir %target_path%\lib
	mkdir %target_path%\bin
)

IF NOT EXIST %target_path%\include\sp.h (
	xcopy spread-bin-4.0.0\include\* %target_path%\include\
	xcopy spread-bin-4.0.0\bin\win32\*  %target_path%\bin\
	xcopy spread-bin-4.0.0\lib\win32\*  %target_path%\lib\
	xcopy spread-bin-4.0.0\docs\sample.spread.conf %target_path%\bin\spread.conf*
)

IF EXIST %absolute_path%\include\boost (
	git clone --recursive --branch boost-1.62.0 https://github.com/boostorg/boost.git
	cd boost
	call bootstrap.bat
	rem Python has not been included; Compilation would fail
	b2 --reconfigure --without-python link=static,shared address-model=%bits% variant=%lower_target%
    b2 headers
	xcopy /y stage\lib\*.lib %absolute_path%\lib\
	xcopy /y stage\lib\*.dll %absolute_path%\bin\
	IF NOT EXIST %absolute_path%\include\boost mkdir %absolute_path%\include\boost
	xcopy /S /y boost %absolute_path%\include\boost\
	cd ..
)

IF EXIST %target_path%\bin\protoc.exe GOTO protobufDone

cd protobuf/vsprojects
git checkout v2.6.1
git clean -f
git checkout *
ECHO #define _SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS >> config.h
devenv.exe protobuf.sln /upgrade

:checkForUpgradeLog

IF NOT EXIST UpgradeLog.htm (
	TIMEOUT /T 30 >nul
	GOTO checkForUpgradeLog
)

IF "%arch%" == "x64" (
	for %%p in (protoc, libprotobuf-lite, libprotobuf, libprotoc) do (
		call ..\..\textreplace.bat %%p.vcxproj Win32 x64
		call ..\..\textreplace.bat %%p.vcxproj MachineX86 MachineX64
	)
)

for %%p in (libprotobuf-lite, libprotobuf, libprotoc) do (
	msbuild /tv:%msvc%.0 /p:Configuration=%target% /p:Platform=%arch% %%p.vcxproj 
	xcopy /Y %target%\%%p.lib  %absolute_path%\lib
)

msbuild /tv:%msvc%.0 /p:Configuration=%target% /p:Platform=%arch% protoc.vcxproj
xcopy /Y %target%\protoc.exe  %absolute_path%\bin 

call extract_includes.bat
xcopy /s /y include\google %absolute_path%\include\

cd ..\..

:protobufDone

rem 
for %%p in (rsc, rsb-protocol, rsb-cpp, rsb-spread) do (
	ECHO Building %%p ...
	cd %%p
	git checkout %rsx_version%
	if not exist build mkdir build
	cd build
	cmake -G %generator% -DCMAKE_INSTALL_PREFIX=%absolute_path% -DPROTOBUF_INCLUDE_DIR=%absolute_path%\include ..
	msbuild ALL.vcxproj /tv:%msvc%.0 /p:Configuration=%target% /p:Platform=%arch%
	msbuild INSTALL.vcxproj /tv:%msvc%.0 /p:Configuration=%target% /p:Platform=%arch%
	cd ..\..
	EXIT 0
)

IF NOT [%rst%] == [] (
	ECHO hello
)
