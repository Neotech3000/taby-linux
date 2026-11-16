# Rose-inspired Taby for Omarchy — Cursor handoff

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

Build **Rose-like capability with Taby-like warmth**, adapted to Omarchy rather
than cloning either product:

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

1. **Chat:** use the OpenCode default model configured on this machine through its
   stateless, text-only `POST /api/experimental/generate/text` path. This endpoint
   does not provide tools. Show which provider/model is active and that prompts
   may leave the computer or incur provider usage charges. Keep Ollama as an
   explicit local-only option, not an automatic download or background model.
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

### Rose/Jarvis-style follow-on

- **Multi-command planning:** translate a natural request into a visible plan;
  ask before actions that affect other apps, files, network, or the device.
- **Research mode:** bounded search/read with sources and a visible progress
  timeline; separate provider/web results from locally stored notes.
- **Connectors:** add one at a time with explicit permissions, local secret
  storage, revoke controls, and a redacted action history.
- **Voice:** push-to-talk first, visible listening state, local transcription
  when available, cancel/mute control. Do not record continuously by default.

## Safety and privacy constraints

- No arbitrary shell, `eval`, unrestricted browser control, or agent tool loop in
  the first plugin.
- Keep data stores under `$XDG_DATA_HOME/taby-linux` with user-only permissions.
- Never put API keys in the repository, prompt, logs, screenshots, or command
  output. Reuse OpenCode's configured credentials through its supported CLI/API;
  do not mint or scrape credentials.
- The OpenCode generation endpoint is text-only and has no OpenCode tool access.
  Do not replace it with `session.prompt` or `opencode run` in a way that silently
  enables shell/file tools.
- Ask before any future feature sends notes, tasks, screenshots, or device state
  to a model provider. A clear backend toggle is required.
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
- Current build milestone: create `omarchy-plugin/` here with a Rose-style
  overlay, an optional small bar widget, and a constrained local bridge to the
  existing OpenCode text-only backend, SQLite tasks/notes, and C6 USB animation
  protocol. Validate it with `omarchy plugin validate`; do not install/enable it
  or alter `shell.json`/Hyprland bindings in this pass.
- OpenCode can reuse the user's configured default model; keep provider
  cost/remote disclosure visible. Ollama is an optional, explicit local backend.
- Initial plugin implementation is now in `omarchy-plugin/`: a dark Rose HUD
  overlay with an orbital badge, animated Taby face and Taby-style quick-action
  chips, plus a small bar launcher and a constrained
  `bin/rose-bridge` for OpenCode text generation, local tasks/notes, and the
  experimental C6 USB animation catalog. The Omarchy manifest validator,
  Python compile, local bridge task/device checks, and a tiny OpenCode response
  check pass. A standalone QML load is still pending because Omarchy injects
  its `qs.*` modules through the host shell.
- The plugin has not been symlinked into `~/.config/omarchy/plugins` and is not
  enabled in the live shell. Local install/uninstall scripts exist but have not
  been run.

## Progress update — 2026-11-16, UI and device validation

- Expanded the overlay to four sections: Chat, Tasks, Notes, and Device. Notes
  are loaded/saved through the local SQLite bridge; chat remains text-only with
  the configured OpenCode model label shown separately in the header. Added a
  dismiss control and empty-state copy.
- The GTK/Quickshell UI does not change firmware. Separately, at the owner's
  request, rebuilt the existing experimental C6 source with ESP-IDF 5.4.2,
  packaged the exact `c6-lcd-1.47` target, and flashed only its reviewed image
  regions (bootloader, partition table, OTA data, app, assets). The installer
  preserved NVS/factory data and verified firmware `1.3.0` / assets `0.2.0-c6`
  by USB readback. The USB confirmation animation was accepted; visual display
  verification still needs the owner.
- QML syntax lint, Python compile, bridge notes/model-status smoke tests, and
  Omarchy manifest validation pass. A standalone Quickshell launch cannot resolve
  Omarchy's injected `qs.*` imports; the plugin remains uninstalled/disabled, so
  actual host-shell visual validation is pending approval to install/enable it.
