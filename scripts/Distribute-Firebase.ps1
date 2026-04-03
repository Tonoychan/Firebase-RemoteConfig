<#
.SYNOPSIS
  Upload a Unity Android/iOS build to Firebase App Distribution via the Firebase CLI.

.PREREQUISITES
  1) Firebase Console: Project Settings > Your apps — copy the App ID (e.g. 1:xxx:android:yyy).
  2) App Distribution: add tester groups or individual testers in the console.
  3) Install Firebase CLI: https://firebase.google.com/docs/cli#install_the_firebase_cli
     (Windows standalone binary, npm i -g firebase-tools, or npx firebase-tools.)
  4) Local: run `firebase login` once. CI: set FIREBASE_TOKEN from `firebase login:ci`.

.USAGE
  $env:FIREBASE_APP_ID = "1:123456789:android:abcdef"
  .\scripts\Distribute-Firebase.ps1 -BuildPath "D:\builds\app.apk" -Groups "internal-testers" -ReleaseNotes "Build 42"

  Optional env: FIREBASE_TOKEN (CI), FIREBASE_CLI (path to firebase executable).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $BuildPath,

    [string] $ReleaseNotes = "",

    [string] $Groups = "",

    [string] $Testers = "",

    [string] $ReleaseNotesFile = "",

    [string] $AppId = ""
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $BuildPath)) {
    Write-Error "Build file not found: $BuildPath"
}

$resolvedAppId = $AppId
if (-not $resolvedAppId) { $resolvedAppId = $env:FIREBASE_APP_ID }
if (-not $resolvedAppId) {
    Write-Error "Set FIREBASE_APP_ID or pass -AppId (Firebase console: Project settings > General > Your apps)."
}

$firebase = $env:FIREBASE_CLI
if (-not $firebase) { $firebase = "firebase" }

$cliArgs = @(
    "appdistribution:distribute",
    (Resolve-Path -LiteralPath $BuildPath).Path,
    "--app",
    $resolvedAppId
)

if ($env:FIREBASE_TOKEN) {
    $cliArgs += @("--token", $env:FIREBASE_TOKEN)
}

if ($ReleaseNotesFile) {
    if (-not (Test-Path -LiteralPath $ReleaseNotesFile)) {
        Write-Error "Release notes file not found: $ReleaseNotesFile"
    }
    $cliArgs += @("--release-notes-file", (Resolve-Path -LiteralPath $ReleaseNotesFile).Path)
}
elseif ($ReleaseNotes) {
    $cliArgs += @("--release-notes", $ReleaseNotes)
}

if ($Groups) {
    $cliArgs += @("--groups", $Groups)
}

if ($Testers) {
    $cliArgs += @("--testers", $Testers)
}

Write-Host "Running: $firebase $($cliArgs -join ' ')" -ForegroundColor Cyan
& $firebase @cliArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
