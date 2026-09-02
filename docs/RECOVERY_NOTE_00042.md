# Recovery note — 00042

A recovery sweep was performed against the connected ChatGPT file Library and the current public repository.

The current repository contains legacy material under `archive/legacy`, including older scripts and project fragments. However, the exact historical source packages named `KIT_UNICO`, `SONPEF/sonpef_unify.ps1`, `CONVGPT`, and `chat_history_bridge.js` were not found by the available repository/file searches in this pass.

Therefore this build does **not** claim that those historical source files were recovered. Their integration registry is intentionally marked as reference/pending recovery rather than falsely marking them as complete.

If those original files are uploaded again, they can be audited and promoted into the build without manual copy/paste reconstruction.

## Current verified baseline

- Manifest V3.
- Explicit `background.service_worker`.
- Service worker contains native-host diagnostics that consume `chrome.runtime.lastError` on disconnect.
- Four icon paths are present in the repository.
- PowerShell 5-compatible validator added.
- Native Messaging is not required for extension boot.
