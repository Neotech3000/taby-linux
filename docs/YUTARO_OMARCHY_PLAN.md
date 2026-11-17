# Yutaro for Omarchy — Cursor handoff

**Status:** design/implementation plan; no Omarchy configuration has been changed.
**Working repo:** this repository root.

## Why this project exists

Hey Taby's public download page currently offers macOS and Windows; Linux is
listed as coming soon. The official desktop application source is not in the
public `TRIIIS-LABS` GitHub organization, which currently exposes only the
physical-device firmware repository. This project is an **unofficial personal
Linux companion**, not a fork or claim of official support.

The current app is a small GTK 4 prototype with local SQLite tasks/notes,
relative reminders while it is running, an OpenCode text-generation backend,
an optional Ollama fallback, and USB animation control for the ESP32-C6-LCD-1.47.
The C6 firmware is experimental. Keep firmware work and the Linux desktop/plugin
separate.

## Inspiration reviewed

Use these as product references, not as assets to copy or claims of endorsement.

- **Hey Taby — “how taby works”** (Instagram, Oct 5, 2026):
  https://www.instagram.com/reel/DeHmvvJgvVt/
- **Hey Taby public product overview:**
  https://www.heytaby.com/ and https://www.heytaby.com/downloads
- **Huw Prosser — Rose introduction** (Instagram, Oct 29, 2026):
  https://www.instagram.com/reel/DfGOQ5pIZqy/
- **Huw Prosser — Rose research capability** (Instagram, Oct 30, 2026):
  https://www.instagram.com/reel/DfIDY9mo5Bn/
- **Huw Prosser — Rose / Busy integration teaser** (Instagram):
  https://www.instagram.com/reel/DfiUyCeIdt2/
- **Huw Prosser — Rose clips/profile:**
  https://www.instagram.com/huwprosser/

I inspected the public first 15 seconds of the Taby “how it works” reel and the
Rose introduction (temporary reference cuts are outside the repo). The Rose
clip shows a dark desktop/HUD composition, small status tabs and data panels,
with a bright circular magenta Rose mark. The Taby clip shows a friendly face
at the top edge, a floating pill-shaped prompt with voice/attachment affordances,
a section menu, and controls for positioning the face. Use those broad visual
ideas—don't copy video frames or claim Rose's unreleased internals.

The function concepts are: Taby's quick hide/show, face reactions, direct
task/note/voice interaction; Rose/Jarvis's stated interest in better research,
multi-command recognition, project assistance, and app integrations. Treat the
captions as the source for Rose capabilities; don't infer hidden tool behavior
from a short teaser.

## Design direction

Build Yutaro with Taby-like warmth and Rose-inspired HUD accents, adapted to
Omarchy rather than cloning either product:

- A focused, keyboard-first overlay with a small animated face, compact history,
  one prompt field, and clear progress/results. Make it easy to dismiss and
  restore without stealing focus permanently.
- Blend the references rather than tracing them: Rose's circular magenta HUD
  badge and dark instrument-panel contrast around Taby's animated face, friendly
  prompt field, and quick-action chips.
- Respect Omarchy's active theme, spacing, and Quickshell conventions. Reuse
  Omarchy surfaces/tokens where available; avoid a second always-visible bar.
- A small optional bar/status affordance may show local-model and physical-device
  state, but the main assistant should be summoned on demand.
- Use layered capabilities: first chat and local productivity data; then safe,
  reviewable multi-step actions and research; later voice and more integrations.

## Functional concept

### First useful release

1. **Chat:** offer OpenCode and local Ollama as explicit backends. The app-level
   OpenCode default is `opencode/big-pickle`; send it through the stateless,
   text-only `POST /api/experimental/generate/text` endpoint with an explicit
   model ref. This endpoint does not provide tools. Show the selected model and
   that OpenCode prompts may leave the computer or incur provider limits/charges.
   Do not change the user's global OpenCode model config. Ollama is local-only,
   never auto-started, and never downloads a model automatically.
2. **Local task and note commands:** keep the current SQLite store. Parse direct
   commands locally so task/note contents are never silently added to a cloud
   prompt. Search or list local data only when the user asks.
3. **Physical Taby:** use the bounded USB serial protocol and animation IDs from
   the selected board's compatible local asset manifest. A missing device must
   not stop digital app use.
4. **Omarchy plugin:** package the UI as a user-owned Quickshell plugin in the
   shape Omarchy expects (manifest + QML entry point). Keep the GTK app/backend
   available as a standalone fallback until the plugin can call the same
   constrained backend reliably.

### Advanced assistant follow-on (Rose/Jarvis inspiration)

- **Multi-command planning:** translate a natural request into a visible plan;
  ask before actions that affect other apps, files, network, or the device.
- **Research mode:** bounded search/read with sources and a visible progress
  timeline; separate provider/web results from locally stored notes.
- **Connectors:** add one at a time with explicit permissions, local secret
  storage, revoke controls, and a redacted action history.
- **Voice:** push-to-talk first, visible listening state, and an explicitly
  enabled ElevenLabs transcription option with clear audio/provider disclosure,
  cancel/mute control, and no background recording by default.

## Safety and privacy constraints

- No arbitrary shell, `eval`, unrestricted browser control, or agent tool loop.
  Workspace reads/edits are confined to the approved Taby checkout; file writes
  require review, and command execution is limited to fixed project checks.
- Internet access is limited to user-triggered OpenCode web searches. Display
  result URLs, treat snippets as untrusted input, and do not fetch authenticated
  pages or perform actions on websites.
- OpenCode chat uses its stateless, tool-free text endpoint and a separate
  explicit web-search request. Yutaro does not inherit OpenCode session shell or
  file tools. File-edit requests go through a constrained bridge: only approved
  project text files are read, sending contents to OpenCode needs separate user
  consent, and the file changes only after the displayed diff is approved.
- Project checks run only from a fixed allowlist after user confirmation; the
  model cannot supply command strings or arguments.
- Keep data stores under `$XDG_DATA_HOME/taby-linux` with user-only permissions.
- Never put API keys in the repository, prompt, logs, screenshots, or command
  output. Reuse OpenCode's configured credentials through its supported CLI/API;
  do not mint or scrape credentials.
- The OpenCode generation endpoint is text-only and has no OpenCode tool access.
  Do not replace it with `session.prompt` or `opencode run` in a way that silently
  enables shell/file tools.
- Ask before any future feature sends notes, tasks, screenshots, or device state
  to a model provider. A clear backend toggle is required.
- Ask separately before sending project file contents to a model provider; keep
  local-model file work on the selected local service.
- Keep firmware flashing separate from the Omarchy plugin and never erase the
  full ESP32 flash or its NVS/factory data.

## Omarchy integration constraints

- Read the installed plugin patterns before implementing. A local working
  example is `~/.config/omarchy/plugins/beam/`; installed plugins are
  user-owned under `~/.config/omarchy/plugins/<plugin-id>/`.
- Do not edit `/usr/share/omarchy/`.
- Do not edit `~/.config/omarchy/shell.json`, Hyprland bindings, or enable a
  plugin during the design phase. When ready, provide an install command or
  proposed binding and get approval before changing user configuration.
- Prefer a Quickshell `overlay`/`bar-widget` plugin manifest and native QML
  components. Don't create a competing status bar or mutate another plugin.
- Validate with `omarchy plugin validate <folder>` before installation and
  document an uninstall path that only removes this plugin.

## Integration notes

- Omarchy uses a Quickshell plugin system; Beam demonstrates a fullscreen
  `PanelWindow` overlay and user-owned plugin installation.
- Inspect the user's existing shell layout before proposing bar placement.
- The GTK prototype is `app.py`; `install.sh` can create a per-user desktop
  launcher.
- OpenCode uses the user's configured default model through a stateless text
  endpoint. This may call a remote provider and may incur usage charges.
- Ollama is an opt-in local backend. Don't download or launch a large model
  without checking free memory and asking.
- The experimental Physical Taby C6 target is USB-only, has no touch, and does
  not use PSRAM. Check the connected device and matching firmware bundle before
  any hardware operation.

## Cursor collaboration protocol

1. Read this file and the app's `README.md` before changing direction.
2. Post proposed architecture/UI decisions here before implementing them so the
   other agent can follow along.
3. Work in small changes; avoid editing `~/.config/omarchy` until the user
   approves an install/config change.
4. After UI/backend work, run `python3 -m py_compile app.py` and exercise the
   local task/note paths. For the firmware repository also run its checker and
   tests; do not flash unless explicitly authorized for that build.
5. Clearly mark what is implemented versus a mockup, and never claim the app is
   official Hey Taby or Huw Prosser's Rose.

## Progress update — 2026-11-16

- The initial working copy was created locally for Cursor collaboration; use
  this repository root as the project entry point.
- Read Omarchy's installed plugin examples (`beam`, `field-notes`, and
  `advanced-workspaces`) and confirmed the shell supports manifest-based
  Quickshell overlays/bar widgets under user-owned plugin directories.
- Current build milestone: create `omarchy-plugin/` here with Yutaro's Rose-inspired
  overlay, an optional small bar widget, and a constrained local bridge to the
  existing OpenCode text-only backend, SQLite tasks/notes, and C6 USB animation
  protocol. Validate it with `omarchy plugin validate`; do not install/enable it
  or alter `shell.json`/Hyprland bindings in this pass.
- OpenCode can reuse the user's configured default model; keep provider
  cost/remote disclosure visible. Ollama is an optional, explicit local backend.
- Initial plugin implementation is now in `omarchy-plugin/`: a dark Rose-inspired HUD
  overlay with an orbital badge, animated Taby face and Taby-style quick-action
  chips, plus a small bar launcher and a constrained
  `bin/rose-bridge` for OpenCode text generation, local tasks/notes, and the
  experimental C6 USB animation catalog. The Omarchy manifest validator,
  Python compile, local bridge task/device checks, and a tiny OpenCode response
  check pass. At this initial stage, a standalone QML load was pending because
  Omarchy injects its `qs.*` modules through the host shell.
- At this initial stage the plugin was not installed or enabled. See the later
  install update below for the current state.

## Progress update — 2026-11-16, UI and device validation

- Expanded the overlay to four sections: Chat, Tasks, Notes, and Device. Notes
  are loaded/saved through the local SQLite bridge; chat remains text-only with
  the selected backend/model shown separately in the header. Added a dismiss
  control and empty-state copy.
- The GTK/Quickshell UI does not change firmware. Separately, at the owner's
  request, rebuilt the existing experimental C6 source with ESP-IDF 5.4.2,
  packaged the exact `c6-lcd-1.47` target, and flashed only its reviewed image
  regions (bootloader, partition table, OTA data, app, assets). The installer
  preserved NVS/factory data and verified firmware `1.3.0` / assets `0.2.0-c6`
  by USB readback. The USB confirmation animation was accepted; visual display
  verification still needs the owner.
- QML syntax lint, Python compile, bridge notes/model-status smoke tests, and
  Omarchy manifest validation pass. Omarchy rejects plugin-root symlinks, so the
  local installer copies the plugin and marks that managed copy for safe updates
  and removal.
- The owner then approved installation. The plugin is enabled in the right bar
  section and has been summoned in the live shell. After fixing live delegate
  binding errors, a shell restart loaded the current files; the fresh log showed
  no Yutaro plugin QML errors. The owner should still confirm the visual appearance.
- The first screenshot exposed two more integration issues: the copied bridge
  looked for `app.py` in the plugin parent, and the active theme's menu surfaces
  were too translucent. The bridge now resolves the source checkout through the
  install marker, and the scrim/card enforce readable opacity while retaining
  theme colors. Installed bridge smoke test and a second live-shell reload pass.
- Added per-app backend/model selection for OpenCode and local Ollama in both the
  GTK companion and Omarchy overlay. Big Pickle is the app-level OpenCode default;
  the user's global OpenCode configuration is unchanged. At first the local Ollama
  endpoint was unavailable; after owner approval the system service was started
  and `qwen2.5:3b` installed. The service is not enabled to start at boot.
- The user renamed the assistant from Rose to **Yutaro**. The plugin ID, manifest,
  QML entry points, bar label, fallback face filename, installer marker, and live
  Omarchy bar entry were migrated to `enochlawrence.yutaro-assistant`. This keeps
  Rose as visual inspiration only, not the assistant's product name.
- Added a user-triggered Search web action through OpenCode's `/api/websearch`;
  Yutaro summarizes bounded snippets with the selected OpenCode or local Ollama
  model and displays source URLs. Search snippets are treated as untrusted data,
  and no shell/filesystem tools or autonomous browsing are exposed. This
  OpenCode installation currently has no web-search provider configured; connect
  one in OpenCode before search requests can succeed.
- OpenCode text chat remains a second UI over its stateless, tool-free text API;
  it does not inherit OpenCode session tools. Any future workspace edits or
  command execution need narrow scopes and per-action approval. ElevenLabs
  dictation remains a future push-to-talk integration, not enabled yet.
- Added a centered spinning lotus loading state sized to one physical inch square
  using the screen density and device-pixel ratio. It appears only while Yutaro
  is waiting for a bridge/model action.
