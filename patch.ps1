# patch.ps1
# OpenCode VS Code extension fix: resume the most recently updated session
# in the workspace folder when the OpenCode panel opens.
#
# What it does:
#   1. Locates the installed `sst-dev.opencode-v2` extension.
#   2. Verifies the call-site string `await this.restoreLastSession()`
#      occurs exactly once in dist/extension.js.
#   3. Backs the file up to extension.js.bak.
#   4. Replaces the call with `await this.loadMostRecentSession()`.
#
# Usage:  powershell -ExecutionPolicy Bypass -File patch.ps1
# After patching, reload the VS Code window (Developer: Reload Window).

$ErrorActionPreference = "Stop"

$find  = "await this.restoreLastSession()"
$repl  = "await this.loadMostRecentSession()"

$candidates = Get-ChildItem -Path "$env:USERPROFILE\.vscode\extensions" -Directory -Filter "sst-dev.opencode-v2-*" -ErrorAction SilentlyContinue
if (-not $candidates) {
    throw "sst-dev.opencode-v2 extension not found under $env:USERPROFILE\.vscode\extensions"
}

$matched = @()
foreach ($dir in $candidates) {
    $js = Join-Path $dir.FullName "dist\extension.js"
    if (-not (Test-Path -LiteralPath $js)) { continue }
    $content = Get-Content -LiteralPath $js -Raw
    $count = ([regex]::Matches($content, [regex]::Escape($find))).Count
    if ($count -eq 1) {
        $matched += [pscustomobject]@{ Path = $js; Version = $dir.Name }
    } elseif ($count -eq 0) {
        Write-Host "SKIP $($dir.Name): already patched or call-site not found." -ForegroundColor Yellow
    } else {
        Write-Host "SKIP $($dir.Name): found $count occurrences of the call-site string (unexpected, bailing out)." -ForegroundColor Yellow
    }
}

if ($matched.Count -eq 0) {
    throw "No patchable extension found. Nothing changed."
}
if ($matched.Count -gt 1) {
    throw "Multiple patchable extension versions found. Pin the version and re-run."
}

$js = $matched[0].Path
Write-Host "Patching $js" -ForegroundColor Cyan

$backup = "$js.bak"
if (-not (Test-Path -LiteralPath $backup)) {
    Copy-Item -LiteralPath $js -Destination $backup
    Write-Host "Backup created: $backup" -ForegroundColor Green
} else {
    Write-Host "Backup already exists: $backup (kept)" -ForegroundColor Yellow
}

$content = Get-Content -LiteralPath $js -Raw
$updated = $content.Replace($find, $repl)
Set-Content -LiteralPath $js -Value $updated -Encoding UTF8 -NoNewline

Write-Host "PATCHED: $js" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Reload the VS Code window (Ctrl+Shift+P -> 'Developer: Reload Window')."
Write-Host "  2. Open the OpenCode panel. It now resumes the most recently updated"
Write-Host "     session in the workspace folder."
Write-Host "  3. Confirm in the 'OpenCode' output channel: 'Loaded most recent session: <id>'."
Write-Host ""
Write-Host "Note: VS Code extension updates overwrite this patch. Re-run this script after updates."
