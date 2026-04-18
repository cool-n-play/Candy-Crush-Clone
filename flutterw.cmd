@echo off
REM If your Android emulator shows as "unsupported" (e.g. sdk gphone x86 / 32-bit):
REM Create an AVD with x86_64 or arm64-v8a (Android Studio Device Manager), or use this
REM wrapper: by default "run -d <that emulator>" falls back to Windows desktop.
REM To only see an error: set FLUTTERW_NO_ANDROID_FALLBACK=1
setlocal EnableExtensions EnableDelayedExpansion
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "TV=%ROOT%\.tool-versions"
if not exist "%TV%" (
  echo .tool-versions not found in %ROOT% 1>&2
  exit /b 1
)
set "LINE="
for /f "usebackq delims=" %%L in (`findstr /b /c:"flutter" "%TV%"`) do (
  set "LINE=%%L"
  goto :have_line
)
:have_line
if not defined LINE (
  echo No flutter line in .tool-versions 1>&2
  exit /b 1
)
for /f "tokens=2" %%V in ("!LINE!") do set "FLUTTER_VER=%%V"
set "FLUTTER_BAT=%USERPROFILE%\.asdf\installs\flutter\!FLUTTER_VER!\bin\flutter.bat"
if not exist "!FLUTTER_BAT!" (
  echo Flutter not installed at !FLUTTER_BAT!. Run: asdf install flutter !FLUTTER_VER! 1>&2
  exit /b 1
)
call :maybe_check_unsupported_device %*
if errorlevel 2 (
  if errorlevel 3 exit /b 1
  exit /b 0
)
if errorlevel 1 exit /b 1
call "!FLUTTER_BAT!" %*
exit /b 0

:maybe_check_unsupported_device
if /I not "%~1"=="run" exit /b 0
set "DEVICE_ID="
set "PREV="
for %%A in (%*) do (
  if "!PREV!"=="-d" set "DEVICE_ID=%%~A"
  if "!PREV!"=="--device-id" set "DEVICE_ID=%%~A"
  set "PREV=%%~A"
)
if not defined DEVICE_ID exit /b 0
call "!FLUTTER_BAT!" devices --machine > "%TEMP%\flutter_devices.json" 2>nul
if errorlevel 1 exit /b 0
set "FLUTTERW_DEVICE_ID=!DEVICE_ID!"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { $id=$env:FLUTTERW_DEVICE_ID; if ([string]::IsNullOrEmpty($id)) { exit 0 }; $p=(Join-Path $env:TEMP 'flutter_devices.json'); if (-not (Test-Path -LiteralPath $p)) { exit 2 }; $j=Get-Content -LiteralPath $p -Raw | ConvertFrom-Json; $d=$j | Where-Object { $_.id -eq $id } | Select-Object -First 1; if (-not $d) { exit 2 }; if ($d.isSupported) { exit 0 }; exit 1 }"
if errorlevel 2 exit /b 0
if errorlevel 1 goto :unsupported_android
exit /b 0

:unsupported_android
if defined FLUTTERW_NO_ANDROID_FALLBACK (
  "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command "& { $id=$env:FLUTTERW_DEVICE_ID; $e=[Console]::Error; $e.WriteLine(''); $e.WriteLine('=== Flutter cannot run on this device: ' + $id + ' (unsupported) ==='); $e.WriteLine('32-bit x86 (ia32) Android emulators are not supported. Use an AVD whose system image is x86_64 or arm64-v8a (Android Studio: Device Manager).'); $e.WriteLine('Or unset FLUTTERW_NO_ANDROID_FALLBACK to auto-run on Windows, or: .\\flutterw.cmd run -d windows'); $e.WriteLine(''); exit 1 }"
  exit /b 1
)
echo.
echo [flutterw] Android device !DEVICE_ID! is not supported by Flutter ^(e.g. 32-bit x86 emulator^).
echo           Running on Windows desktop instead. For a real Android build, use an x86_64 or arm64 AVD.
echo           ^(set FLUTTERW_NO_ANDROID_FALLBACK=1 to show only the error.^)
echo.
set "EXTRA="
set "WAIT_DEV="
set "WAIT_FLAG="
for %%A in (%*) do (
  if defined WAIT_DEV (
    if "%%~A"=="!DEVICE_ID!" (
      set "WAIT_DEV="
      set "WAIT_FLAG="
    ) else (
      set "EXTRA=!EXTRA! !WAIT_FLAG! %%~A"
      set "WAIT_DEV="
      set "WAIT_FLAG="
    )
  ) else if "%%~A"=="-d" (
    set "WAIT_DEV=1"
    set "WAIT_FLAG=-d"
  ) else if "%%~A"=="--device-id" (
    set "WAIT_DEV=1"
    set "WAIT_FLAG=--device-id"
  ) else if /I not "%%~A"=="run" (
    set "EXTRA=!EXTRA! %%~A"
  )
)
call "!FLUTTER_BAT!" run -d windows!EXTRA!
exit /b 2
