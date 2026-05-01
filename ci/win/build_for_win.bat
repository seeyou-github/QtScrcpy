@echo off
setlocal

echo(
echo(
echo ---------------------------------------------------------------
echo check ENV
echo ---------------------------------------------------------------

set "vcvarsall=%ENV_VCVARSALL%"
set "qt_root=%ENV_QT_PATH%"

echo ENV_QT_PATH %qt_root%

set "script_path=%~dp0"
set "old_cd=%cd%"
cd /d "%script_path%"

set "cpu_mode=x86"
set "build_mode=RelWithDebInfo"
set "cmake_vs_build_mode=Win32"
set "qt_platform_dir="
set "qt_cmake_path="
set "vcvars_arch=x86"
set "errno=1"

echo(
echo(
echo ---------------------------------------------------------------
echo check build param[Debug/Release/MinSizeRel/RelWithDebInfo]
echo ---------------------------------------------------------------

if /i "%~1"=="Debug" goto build_mode_ok
if /i "%~1"=="Release" goto build_mode_ok
if /i "%~1"=="MinSizeRel" goto build_mode_ok
if /i "%~1"=="RelWithDebInfo" goto build_mode_ok
echo error: unknown build mode -- %~1
goto return

:build_mode_ok
set "build_mode=%~1"

if /i "%~2"=="x86" (
    set "cpu_mode=x86"
    set "cmake_vs_build_mode=Win32"
    set "vcvars_arch=x86"
)
if /i "%~2"=="x64" (
    set "cpu_mode=x64"
    set "cmake_vs_build_mode=x64"
    set "vcvars_arch=amd64"
)
if /i not "%~2"=="x86" if /i not "%~2"=="x64" echo error: unknown cpu mode -- %~2 & goto return

call :resolve_qt_platform_dir
if not defined qt_platform_dir echo error: qt platform dir not found under -- %qt_root% & goto return
set "qt_cmake_path=%qt_platform_dir%\lib\cmake\Qt5"

echo current build mode: %build_mode% %cpu_mode%
echo qt platform dir: %qt_platform_dir%
echo qt cmake path: %qt_cmake_path%

if not exist "%vcvarsall%" call :find_vcvarsall
if not exist "%vcvarsall%" echo error: vcvarsall.bat not found -- %vcvarsall% & goto return
if not exist "%qt_cmake_path%" echo error: qt cmake path not found -- %qt_cmake_path% & goto return

echo(
echo(
echo ---------------------------------------------------------------
echo begin cmake build
echo ---------------------------------------------------------------

echo initialize msvc env: %vcvarsall% %vcvars_arch%
call "%vcvarsall%" %vcvars_arch%
if errorlevel 1 echo vcvarsall failed & goto return

set "output_path=%script_path%..\..\output"
if exist "%output_path%" rmdir /q /s "%output_path%"

set "temp_path=%script_path%..\build_temp"
if exist "%temp_path%" rmdir /q /s "%temp_path%"
md "%temp_path%"
cd /d "%temp_path%"

echo cmake params: -DCMAKE_PREFIX_PATH=%qt_cmake_path% -DCMAKE_BUILD_TYPE=%build_mode% -G "Visual Studio 17 2022" -A %cmake_vs_build_mode%

cmake -DCMAKE_PREFIX_PATH="%qt_cmake_path%" -DCMAKE_BUILD_TYPE=%build_mode% -G "Visual Studio 17 2022" -A %cmake_vs_build_mode% ../..
if errorlevel 1 echo cmake failed & goto return

cmake --build . --config %build_mode% -j8
if errorlevel 1 echo cmake build failed & goto return

echo(
echo(
echo ---------------------------------------------------------------
echo finish!!!
echo ---------------------------------------------------------------

set "errno=0"

:return
cd /d "%old_cd%"
endlocal & exit /B %errno%

:find_vcvarsall
set "vswhere=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%vswhere%" goto :eof
for /f "usebackq delims=" %%I in (`"%vswhere%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "vcvarsall=%%I\VC\Auxiliary\Build\vcvarsall.bat"
goto :eof

:resolve_qt_platform_dir
if exist "%qt_root%\lib\cmake\Qt5" (
    set "qt_platform_dir=%qt_root%"
    goto :eof
)
if /i "%cpu_mode%"=="x64" (
    for /d %%D in ("%qt_root%\*") do (
        if exist "%%~fD\lib\cmake\Qt5" (
            echo %%~nxD | findstr /i "64 msvc win64" >nul
            if not errorlevel 1 (
                set "qt_platform_dir=%%~fD"
                goto :eof
            )
        )
    )
) else (
    for /d %%D in ("%qt_root%\*") do (
        if exist "%%~fD\lib\cmake\Qt5" (
            echo %%~nxD | findstr /i "64" >nul
            if errorlevel 1 (
                set "qt_platform_dir=%%~fD"
                goto :eof
            )
        )
    )
)
for /d %%D in ("%qt_root%\*") do (
    if exist "%%~fD\lib\cmake\Qt5" (
        set "qt_platform_dir=%%~fD"
        goto :eof
    )
)
goto :eof
