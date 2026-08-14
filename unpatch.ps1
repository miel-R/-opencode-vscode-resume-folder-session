# unpatch.ps1
# Restores the original dist/extension.js from extension.js.bak for the
# sst-dev.opencode-v2 extension.
#
# Usage:  powershell -ExecutionPolicy Bypass -File unpatch.ps1

$ErrorActionPreference = "Stop"

$candidates = Get-ChildItem -Path "$env:USERPROFILE\.vscode\extensions" -Directory -Filter "sst-dev.opencode-v2-*" -ErrorAction SilentlyContinue
if (-not $candidates) {
    throw "sst-dev.opencode-v2 extension not found under $env:USERPROFILE\.vscode\extensions"
}

$restored = $false
foreach ($dir in $candidates) {
    $js = Join-Path $dir.FullName "dist\extension.js"
    $backup = "$js.bak"
    if (-not (Test-Path -LiteralPath $backup)) { continue }
    Copy-Item -LiteralPath $backup -Destination $js -Force
    Write-Host "RESTORED: $js" -ForegroundColor Green
    Remove-Item -LiteralPath $backup
    Write-Host "Removed backup: $backup" -ForegroundColor Yellow
    $restored = $true
}

if (-not $restored) {
    Write-Host "No backup found; nothing to restore." -ForegroundColor Yellow
}
Write-Host "Reload the VS Code window to apply."
