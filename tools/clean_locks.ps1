# Clears common locked Flutter/Android build folders on Windows (esp. OneDrive).
# Usage (from project root):
#   powershell -ExecutionPolicy Bypass -File tools\clean_locks.ps1

$ErrorActionPreference = "SilentlyContinue"
$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $root "pubspec.yaml"))) {
  $root = Get-Location
}

Write-Host "Project: $root"

$env:JAVA_HOME = if (Test-Path "C:\Program Files\Java\jdk-17") {
  "C:\Program Files\Java\jdk-17"
} else {
  $env:JAVA_HOME
}
if ($env:JAVA_HOME) {
  $env:PATH = "$env:JAVA_HOME\bin;C:\src\flutter\bin;" + $env:PATH
}

# Stop Gradle daemons
$gradlew = Join-Path $root "android\gradlew.bat"
if (Test-Path $gradlew) {
  Push-Location (Join-Path $root "android")
  .\gradlew.bat --stop 2>$null
  Pop-Location
}

Get-Process java, dart -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

$targets = @(
  (Join-Path $root "build"),
  (Join-Path $root "android\.gradle"),
  (Join-Path $root "android\app\build"),
  (Join-Path $root ".dart_tool\flutter_build"),
  # Android outputs are redirected here (see android/build.gradle.kts)
  (Join-Path $env:LOCALAPPDATA "flutter_doc_analyser_build")
)

foreach ($t in $targets) {
  if (Test-Path $t) {
    Write-Host "Removing $t"
    cmd /c "rmdir /s /q `"$t`"" | Out-Null
    if (Test-Path $t) {
      Get-ChildItem -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Attributes = "Normal" }
      Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $t) {
      Write-Host "  STILL LOCKED: $t" -ForegroundColor Yellow
    } else {
      Write-Host "  OK" -ForegroundColor Green
    }
  }
}

Write-Host ""
Write-Host "Done. If anything is still locked:" -ForegroundColor Cyan
Write-Host "  1) Pause OneDrive sync for this folder"
Write-Host "  2) Close Android Studio / other flutter run windows"
Write-Host "  3) Re-run this script, then: flutter run"
