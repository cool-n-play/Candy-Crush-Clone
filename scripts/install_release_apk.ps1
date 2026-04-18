# Installs the release APK over an existing install (no manual uninstall).
# Paths:
#   Absolute: C:\repo\migration\Candy-Crush-Clone\build\app\outputs\flutter-apk\app-release.apk
#   Relative to project root: build\app\outputs\flutter-apk\app-release.apk
param(
  [string]$Apk = (Join-Path $PSScriptRoot "..\build\app\outputs\flutter-apk\app-release.apk")
)
$ErrorActionPreference = "Stop"
$adb = @(
  "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
  if ($env:ANDROID_HOME) { Join-Path $env:ANDROID_HOME "platform-tools\adb.exe" }
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $adb) {
  Write-Error "adb.exe not found. Add Android SDK platform-tools to PATH or set ANDROID_HOME."
}
if (-not (Test-Path $Apk)) {
  Write-Error "APK not found: $Apk — run: flutter build apk --release"
}
& $adb devices
& $adb install -r $Apk
