# opencode-vscode-resume-folder-session

Fix for the **OpenCode VS Code extension** (`sst-dev.opencode-v2`) so that
opening the OpenCode panel **resumes the most recently updated session in the
current workspace folder** instead of restoring a stale persisted session (or
starting a blank one).

## The problem

When you open the OpenCode panel:

1. The extension starts a headless server: `opencode serve --port 4096`.
2. It fetches the folder's sessions (`GET /session?directory=<workspacePath>`).
3. It then calls `restoreLastSession()` — if a `currentSessionId` was
   persisted in VS Code `workspaceState` (key `opencode-state-<workspacePath>`)
   **and that session still exists in the folder**, the panel restores **that**
   session and returns.
4. Only if the persisted id is missing/invalid does it fall through to
   `loadMostRecentSession()`, which resumes `sessions[0]` — the most recently
   updated session in the folder.

The extension *already contains* the "search the folder first" logic — it just
never runs it, because the persisted `currentSessionId` shadows the most recent
session. Symptom: you open the panel and it lands on an old/empty/new
conversation even though your real conversation lives in the same folder.

This patch makes the panel **always** continue the folder's most recently
updated session on open.

## What the patch changes

One call site in `dist/extension.js` of the installed extension:

```diff
- await this.restoreLastSession(),
+ await this.loadMostRecentSession(),
```

`restoreLastSession` becomes dead code; the session dropdown still works for
switching to any other folder session (that choice is then persisted for the
rest of the current session).

## Usage

### Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File patch.ps1
```

### macOS / Linux

```bash
bash patch.sh
```

Then:

1. Reload the VS Code window (`Ctrl+Shift+P` → **Developer: Reload Window**).
2. Open the OpenCode panel. It resumes the most recently updated session in
   the workspace folder.
3. Verify in the **OpenCode** output channel:
   `Loaded most recent session: <session-id>`.

### Reverting

```powershell
powershell -ExecutionPolicy Bypass -File unpatch.ps1
```

(The original file is kept as `extension.js.bak` next to the patched one.)

## Notes / caveats

- **Extension updates overwrite the patch.** The extension is versioned
  `0.1.x` (Beta) — re-run the script after every update. The script verifies
  the call-site string occurs exactly once, so it will refuse to double-patch
  or patch an unexpected build.
- **Most-recent-wins:** the panel now resumes the most recently *updated*
  folder session. An accidentally created empty session will win over your
  real conversation. If that happens, either switch via the session dropdown
  or delete the empty session (`opencode session delete <id>` from a
  terminal).
- **Terminal TUI unaffected:** this patch only covers the VS Code panel.
  `opencode -c` in a terminal uses its own project-scoped matching; there,
  continue a specific session with `opencode -s <session-id>` or use
  `/sessions` in the TUI.

## How it was diagnosed

- Sessions are stored per workspace folder (`directory` column); the extension
  already scopes `session.list` by `directory`.
- The panel's open flow is `getSessions() → restoreLastSession() →
  loadMostRecentSession()` (minified `dist/extension.js` of
  `sst-dev.opencode-v2`).
- Persisted state lives in VS Code `workspaceState` under
  `opencode-state-<workspacePath>` (including `currentSessionId`).

## License

MIT
