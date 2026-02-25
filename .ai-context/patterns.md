# Patterns

## Task registry (5 fields)

```
"label|desc_var|check_fn|apply_fn|status_fn"
```

Registries are `_UPPERCASE_TASKS` arrays. Search modes iterate all 34 arrays listed in `_SEARCH_ARRAYS` in `src/menu.sh`.

## check/status/apply pattern

- `xxx::check()` — returns 0 if everything is ok
- `xxx::status()` — string with issues (empty if ok)
- `xxx::apply()` — interactive wizard (individual modules)
- `xxx::run()` — submenu with task registry (sub-aggregators)

## Wizard pattern (individual tasks)

`while true` + status display + dynamic options + Back/Exit.

## Post-install detection

- `_xxx::is_installed()` — on-disk check (dpkg, files, `command -v`)
- `_xxx::session_ready()` — PATH/session check
- Allows detecting "restart needed"

## Group membership detection

- `_xxx::user_in_group()` — on-disk check via `getent group`
- `_xxx::session_ready()` — session check via `id -nG`
- Allows detecting "restart needed" (group assigned but not active in session)

## gum wrappers

`gum::choose`, `gum::filter`, `gum::input` — all capture exit code and propagate SIGINT (130) with `exit 130`. Do NOT use `2>/dev/null` (gum renders UI on stderr).

## APT patterns

- `dpkg -l | grep '^ii'` instead of `dpkg -s` (rc state)
- `hash -r` after apt install/remove (bash command cache)
- `apt-get update` protected with if/else (can fail with set -e)
- `chmod 644` after `sudo mv` from mktemp (apt runs as `_apt`)
- `ui::flush_input` before sudo (gum leaves escape sequences on /dev/tty)

## GNOME patterns

- gsettings: checks via `gsettings get`, apply via `gsettings set || true`, reset via `gsettings reset || true`
- Custom keybindings: `dconf write` with unique path (`debian-setup-terminal`)
- Extensions: cache with `_extensions::refresh()`, individual management like VS Code wizard
- CSS marker: `/* debian-setup: vte padding */` for own snippets in gtk.css
- GTK4 symlink: resolve to regular file before adding custom CSS

## Shared Mullvad repo

Browser and VPN share repo/GPG key. Both `remove()` verify if the other is installed before cleaning up.

## Flatpak modules

Check `command -v flatpak` before installing. Clear error if not available.
