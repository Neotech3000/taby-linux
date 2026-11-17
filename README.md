# Taby for Linux (unofficial)

A small local-first Linux companion inspired by Hey Taby. The official desktop
app is currently listed for macOS and Windows; this is an independent MVP, not
an official Hey Taby build.

## What works

- Local SQLite tasks and notes.
- A simple chat UI with explicit commands (`add/create task …`, `list tasks`,
  `remind me to … in 10 minutes`, `note title: body`, `find notes …`).
- A model picker for OpenCode and local Ollama. OpenCode defaults to
  `opencode/big-pickle` using its stateless text endpoint; this app-level choice
  does not rewrite your global OpenCode config.
- Explicit `search web <query>` uses OpenCode's configured search provider and
  returns source links; it does not browse logged-in sites or execute actions.
  A search provider must be connected/configured in OpenCode first; Yutaro does
  not store provider credentials.
- Optional local Ollama models discovered on `127.0.0.1:11434`. The app never
  starts Ollama or downloads a model for you.
- USB discovery and approved animation playback for the Physical Taby firmware.
- USB animation support when pointed to a compatible local firmware asset pack.

Tasks and notes stay in `~/.local/share/taby-linux/taby.db`; chat history is
kept in memory for the current app run only. Task and note commands are handled locally and are not
sent to OpenCode. Free-form chat goes through OpenCode's stateless generation
API, with no tool or shell access, and may be sent to the selected provider.
Local Ollama is contacted only on localhost. The app does not connect to Hey
Taby Cloud, execute shell commands, or flash firmware.
Calendar sync, voice input, web actions, and the official Taby Brain are not
implemented yet.

## Run

Install Python 3, GTK 4, PyGObject, and (optionally) pyserial using your Linux
distribution's packages. Then run:

```sh
cd taby-linux
python3 app.py
```

If needed, install the distro packages for Python GTK 4 and pyserial (for
example, `python-gobject`/`python3-gobject` and `python3-serial`). Do not install
PyGObject into a pip virtual environment; use your distro package manager.

The chat pane is a separate UI over OpenCode's stateless, tool-free text API. It
lets you switch between OpenCode and Local Ollama and choose an available model.
OpenCode uses your existing connection and defaults to Big Pickle, though
provider limits may apply. Model prompts may be sent to the
selected provider. **Search web** is user-triggered, uses the search provider
configured in OpenCode, and returns source URLs; connect a provider in OpenCode
before using search. Yutaro does not get arbitrary browser, login, filesystem,
or shell access. Local Ollama is contacted only on
`127.0.0.1`; it is not auto-started and the app never downloads models without
asking. To use Ollama, start it and install a model that fits your computer:

```sh
ollama serve
ollama pull qwen2.5:3b
```

The app stores no API keys. To make a launcher appear in your desktop menu, run
`./install.sh`; it only writes a `.desktop` file under
`~/.local/share/applications`.

## Physical Taby

The app scans `/dev/ttyACM*` and `/dev/ttyUSB*`, sends the documented newline
USB protocol, and only exposes animation IDs in the local C6 manifest. On Linux,
serial access may require adding your account to the distro's serial-device
group, then logging out and back in. The app never modifies firmware.

The display target and model artwork are experimental. The bundled preview and
assets remain Taby artwork and must not be rebranded as a different character.
To use the USB animation controls, set `TABY_ASSETS_DIR` to a compatible local
firmware asset-pack directory containing its `manifest.json`. Firmware source
and build artifacts are intentionally not included in this repository.

## Omarchy plugin prototype

The current Yutaro overlay/bar widget source is in `omarchy-plugin/`.
It uses the same local backend and has passed `omarchy plugin validate`, but is
not installed or enabled by default. See
`docs/YUTARO_OMARCHY_PLAN.md` before helping Cursor extend it.

## License and project status

This is an unofficial, experimental personal project and is not affiliated with
Hey Taby, Omarchy, or Huw Prosser. No license has been granted for reuse yet;
public visibility does not itself grant permission to copy, modify, or
redistribute the project. Taby names and artwork remain their respective
owners' property.
