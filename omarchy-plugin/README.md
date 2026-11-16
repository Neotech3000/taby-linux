# Rose Assistant Omarchy plugin (development)

This is a Quickshell overlay + optional bar-widget plugin for Omarchy. It uses
the companion's local SQLite store, OpenCode text-only generation, and the
bounded USB animation protocol. It does not invoke shell commands from the model,
modify Hyprland configuration, or install itself.

Validate the manifest without changing your active shell:

```sh
omarchy plugin validate ./omarchy-plugin
```

The current development build is not installed or enabled. From the repository
root, after review, install
the local symlink with `./install-local.sh`, then enable it explicitly with the
printed `omarchy plugin enable` command. The script never edits shell.json or
Hyprland bindings. `./uninstall-local.sh` only removes its own symlink.

The Rose overlay asks OpenCode's stateless text-generation endpoint, which has no
tool access. It sends only conversational chat turns—not local task or note
commands. Requests may go to the model provider configured in OpenCode and may
incur usage charges. Local task/note commands go through `bin/rose-bridge`.
The animated face and USB animation catalog are optional; configure compatible
local assets rather than expecting firmware or artwork to be bundled here.
