#!/usr/bin/env bash
# patch.sh — macOS/Linux equivalent of patch.ps1.
# OpenCode VS Code extension fix: resume the most recently updated session
# in the workspace folder when the OpenCode panel opens.
#
# Usage:  bash patch.sh

set -euo pipefail

FIND="await this.restoreLastSession()"
REPL="await this.loadMostRecentSession()"

shopt -s nullglob
candidates=("$HOME"/.vscode/extensions/sst-dev.opencode-v2-*/dist/extension.js)

if [ "${#candidates[@]}" -eq 0 ]; then
  echo "ERROR: sst-dev.opencode-v2 extension not found under $HOME/.vscode/extensions" >&2
  exit 1
fi

matched=()
for js in "${candidates[@]}"; do
  count=$(grep -oF -- "$FIND" "$js" | wc -l | tr -d ' ')
  if [ "$count" -eq 1 ]; then
    matched+=("$js")
  elif [ "$count" -eq 0 ]; then
    echo "SKIP $(basename "$(dirname "$(dirname "$js")")"): already patched or call-site not found."
  else
    echo "SKIP $(basename "$(dirname "$(dirname "$js")")"): found $count occurrences (unexpected)."
  fi
done

if [ "${#matched[@]}" -eq 0 ]; then
  echo "ERROR: no patchable extension found. Nothing changed." >&2
  exit 1
fi

if [ "${#matched[@]}" -gt 1 ]; then
  echo "ERROR: multiple patchable extension versions found. Pin the version and re-run." >&2
  exit 1
fi

js="${matched[0]}"
echo "Patching $js"

backup="$js.bak"
if [ ! -f "$backup" ]; then
  cp "$js" "$backup"
  echo "Backup created: $backup"
else
  echo "Backup already exists: $backup (kept)"
fi

sed -i "s/$FIND/$REPL/" "$js"
echo "PATCHED: $js"
echo ""
echo "Next steps:"
echo "  1. Reload the VS Code window (Cmd/Ctrl+Shift+P -> 'Developer: Reload Window')."
echo "  2. Open the OpenCode panel. It now resumes the most recently updated session in the workspace folder."
echo "  3. Confirm in the 'OpenCode' output channel: 'Loaded most recent session: <id>'."
echo ""
echo "Note: VS Code extension updates overwrite this patch. Re-run this script after updates."
