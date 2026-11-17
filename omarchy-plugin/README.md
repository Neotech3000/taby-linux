# Yutaro Assistant Omarchy plugin (development)

This is a Quickshell overlay + optional bar-widget plugin for Omarchy. It uses
the companion's local SQLite store, OpenCode text-only generation, and the
bounded USB animation protocol. It does not invoke shell commands from the model,
modify Hyprland configuration, or install itself.

The overlay has Chat, Tasks, Notes, and Device sections. Chat can switch between
OpenCode and Local Ollama, and select available models; it defaults to OpenCode's
`opencode/big-pickle`. Task/note actions are local and never enter model prompts.

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
incur usage charges. Local task/note commands go through `bin/rose-bridge`.
The animated face and USB animation catalog are optional; configure compatible
local assets rather than expecting firmware or artwork to be bundled here.
