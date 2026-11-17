# Yutaro Assistant Omarchy plugin (development)

This is a Quickshell overlay + optional bar-widget plugin for Omarchy. It uses
the companion's local SQLite store, OpenCode text-only generation, and the
bounded USB animation protocol. It does not invoke shell commands from the model,
modify Hyprland configuration, or install itself.

The overlay has Chat, Tasks, Notes, and Device sections. Chat can switch between
OpenCode and Local Ollama, and select available models; it defaults to OpenCode's
`opencode/big-pickle`. Task/note actions are local and never enter model prompts.
Yutaro is a separate interface over OpenCode's stateless, tool-free text API.
Web search is explicit (`search web <query>` or the Search web chip) and uses an
OpenCode search provider you have connected/configured; results are returned
with source URLs. Connect a search provider in OpenCode before using it. Yutaro
does not get arbitrary browser, login, filesystem, or shell access and does not
store search-provider credentials.

Validate the manifest without changing your active shell:

```sh
omarchy plugin validate ./omarchy-plugin
```

From the repository root, `./install-local.sh` copies the plugin into
`~/.config/omarchy/plugins/` (Omarchy rejects plugin-root symlinks) and validates
the copy. Then enable it explicitly with the printed `omarchy plugin enable`
command. Enabling updates the shell's plugin/bar configuration, but does not add
a keybinding. `./uninstall-local.sh` disables and removes only this script's
marked copy.

The Yutaro overlay asks OpenCode's stateless text-generation endpoint, which has no
tool access. It sends only conversational chat turns—not local task or note
commands. Requests may go to the model provider configured in OpenCode and may
incur usage charges. Web search is a separate, explicit call to OpenCode's
configured search provider. Local task/note commands go through `bin/rose-bridge`.
The animated face and USB animation catalog are optional; configure compatible
local assets rather than expecting firmware or artwork to be bundled here.
