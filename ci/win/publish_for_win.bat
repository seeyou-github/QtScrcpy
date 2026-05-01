@echo off
setlocal

echo(
echo(
echo ---------------------------------------------------------------
echo check ENV
echo ---------------------------------------------------------------

set "vcvarsall=%ENV_VCVARSALL%"
set "qt_root=%ENV_QT_PATH%"

echo ENV_VCVARSALL %ENV_VCVARSALL%
echo ENV_QT_PATH %ENV_QT_PATH%

set "script_path=%~dp0"
set "old_cd=%cd%"
cd /d "%script_path%"

set "cpu_mode=x86"
set "publish_dir=%~2"
set "qt_bin_path="
set "qt_platform_dir="
set "errno=1"

if /i "%~1"=="x86" set "cpu_mode=x86"
if /i "%~1"=="x64" set "cpu_mode=x64"
if /i not "%~1"=="x86" if /i not "%~1"=="x64" echo error: unknown cpu mode -- %~1 & goto return

echo current build mode: %cpu_mode%
echo current publish dir: %publish_dir%

set "jar_path=%script_path%..\..\QtScrcpy\QtScrcpyCore\src\third_party\scrcpy-server"
set "keymap_path=%script_path%..\..\keymap"
set "config_path=%script_path%..\..\config"

if /i "%cpu_mode%"=="x86" (
    set "publish_path=%script_path%%publish_dir%\"
    set "release_path=%script_path%..\..\output\x86\RelWithDebInfo"
    set "vcvars_arch=x86"
) else (
    set "publish_path=%script_path%%publish_dir%\"
    set "release_path=%script_path%..\..\output\x64\RelWithDebInfo"
    set "vcvars_arch=amd64"
)

call :resolve_qt_platform_dir
if not defined qt_platform_dir echo error: qt platform dir not found under -- %qt_root% & goto return
set "qt_bin_path=%qt_platform_dir%\bin"

if not exist "%vcvarsall%" call :find_vcvarsall
if not exist "%vcvarsall%" echo error: vcvarsall.bat not found -- %vcvarsall% & goto return
if not exist "%qt_bin_path%" echo error: qt bin path not found -- %qt_bin_path% & goto return
if not exist "%release_path%" echo error: release path not found -- %release_path% & goto return

set "PATH=%qt_bin_path%;%PATH%"

call "%vcvarsall%" %vcvars_arch%
if errorlevel 1 echo vcvarsall failed & goto return

if exist "%publish_path%" rmdir /s /q "%publish_path%"

xcopy "%release_path%" "%publish_path%" /E /Y
if errorlevel 1 echo copy release files failed & goto return
xcopy "%jar_path%" "%publish_path%" /Y
if errorlevel 1 echo copy scrcpy-server failed & goto return
xcopy "%keymap_path%" "%publish_path%keymap\" /E /Y
if errorlevel 1 echo copy keymap failed & goto return
xcopy "%config_path%" "%publish_path%config\" /E /Y
if errorlevel 1 echo copy config failed & goto return

windeployqt "%publish_path%\QtScrcpy.exe"
if errorlevel 1 echo windeployqt failed & goto return

if exist "%publish_path%\iconengines" rmdir /s /q "%publish_path%\iconengines"
if exist "%publish_path%\translations" rmdir /s /q "%publish_path%\translations"

if exist "%publish_path%\imageformats\qgif.dll" del "%publish_path%\imageformats\qgif.dll"
if exist "%publish_path%\imageformats\qicns.dll" del "%publish_path%\imageformats\qicns.dll"
if exist "%publish_path%\imageformats\qico.dll" del "%publish_path%\imageformats\qico.dll"
if exist "%publish_path%\imageformats\qsvg.dll" del "%publish_path%\imageformats\qsvg.dll"
if exist "%publish_path%\imageformats\qtga.dll" del "%publish_path%\imageformats\qtga.dll"
if exist "%publish_path%\imageformats\qtiff.dll" del "%publish_path%\imageformats\qtiff.dll"
if exist "%publish_path%\imageformats\qwbmp.dll" del "%publish_path%\imageformats\qwbmp.dll"
if exist "%publish_path%\imageformats\qwebp.dll" del "%publish_path%\imageformats\qwebp.dll"

if /i "%cpu_mode%"=="x86" (
    if exist "%publish_path%\vc_redist.x86.exe" del "%publish_path%\vc_redist.x86.exe"
    copy /Y "C:\Windows\SysWOW64\msvcp140_1.dll" "%publish_path%\msvcp140_1.dll"
    if errorlevel 1 echo copy msvcp140_1.dll failed & goto return
    copy /Y "C:\Windows\SysWOW64\msvcp140.dll" "%publish_path%\msvcp140.dll"
    if errorlevel 1 echo copy msvcp140.dll failed & goto return
    copy /Y "C:\Windows\SysWOW64\vcruntime140.dll" "%publish_path%\vcruntime140.dll"
    if errorlevel 1 echo copy vcruntime140.dll failed & goto return
) else (
    if exist "%publish_path%\vc_redist.x64.exe" del "%publish_path%\vc_redist.x64.exe"
    copy /Y "C:\Windows\System32\msvcp140_1.dll" "%publish_path%\msvcp140_1.dll"
    if errorlevel 1 echo copy msvcp140_1.dll failed & goto return
    copy /Y "C:\Windows\System32\msvcp140.dll" "%publish_path%\msvcp140.dll"
    if errorlevel 1 echo copy msvcp140.dll failed & goto return
    copy /Y "C:\Windows\System32\vcruntime140.dll" "%publish_path%\vcruntime140.dll"
    if errorlevel 1 echo copy vcruntime140.dll failed & goto return
    copy /Y "C:\Windows\System32\vcruntime140_1.dll" "%publish_path%\vcruntime140_1.dll"
    if errorlevel 1 echo copy vcruntime140_1.dll failed & goto return
)

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
if exist "%qt_root%\bin\windeployqt.exe" (
    set "qt_platform_dir=%qt_root%"
    goto :eof
)
if /i "%cpu_mode%"=="x64" (
    for /d %%D in ("%qt_root%\*") do (
        if exist "%%~fD\bin\windeployqt.exe" (
            echo %%~nxD | findstr /i "64 msvc win64" >nul
            if not errorlevel 1 (
                set "qt_platform_dir=%%~fD"
                goto :eof
            )
        )
    )
) else (
    for /d %%D in ("%qt_root%\*") do (
        if exist "%%~fD\bin\windeployqt.exe" (
            echo %%~nxD | findstr /i "64" >nul
            if errorlevel 1 (
                set "qt_platform_dir=%%~fD"
                goto :eof
            )
        )
    )
)
for /d %%D in ("%qt_root%\*") do (
    if exist "%%~fD\bin\windeployqt.exe" (
        set "qt_platform_dir=%%~fD"
        goto :eof
    )
)
goto :eof
