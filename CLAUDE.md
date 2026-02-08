# debian-setup

CLI en Bash para automatizar tareas post-instalacion en Debian.

## Stack

- **Shell**: Bash con `set -euo pipefail`
- **UI**: [gum](https://github.com/charmbracelet/gum) (Charm) — dependencia hard
- **Palette**: Catppuccin Mocha (ANSI + hex constants en `src/lib/colors.sh`)
- **Logs**: XDG compliant — `$XDG_STATE_HOME/debian-setup/logs/YYYY-MM-DD.log`

## Conventions

- **Idioma**: Codigo y mensajes CLI en ingles, comunicacion con usuario en espanol
- **Commits**: Semantic commits (feat/fix/chore/refactor). SIN referencias a Claude AI. SIN Co-Authored-By
- **Commits firmados**: SSH signing con ED25519 (configurado en git config)
- **Branches**: `develop` (trabajo), `main` (releases)
- **Namespaces**: 2 niveles con `::` (log::info, ui::header, health::run). NUNCA 3 niveles
- **Load guards**: `[[ -n "${_LIB_X_LOADED:-}" ]] && return 0` en cada fichero sourced
- **Labels**: Title Case ("Configure SSH Keys", "Configure Build Essentials")
- **Sourcing order**: colors > xdg > log > system > gum > ui > apt (lib) > menu > modules

## Architecture

### Header persistente
Se pinta una vez. `_UI_CONTENT_ROW` guarda la fila del cursor (via `\033[6n`, 1-indexed). `ui::clear_content` usa `tput cup $((_UI_CONTENT_ROW - 1)) 0` + `tput ed` (0-indexed).

### Logging
- `log::info` — terminal + fichero
- `log::nav` — solo terminal (breadcrumbs de navegacion)
- `log::ok/warn/error` — terminal + fichero
- `log::break` — separacion de 1 linea

### Menus
- Escape/cadena vacia = Back. En menu principal = Exit
- Todos los menus llevan "Back" y "Exit" al final
- `gum::choose` para menus pequenos (<5 items)
- `gum::filter` para menus grandes (5+ items)
- Los `run()` de modulos NO ejecutan checks — muestran labels simples (strip "Configure ")

### Patron wizard (tareas individuales)
`while true` + status display + opciones dinamicas + Back/Exit.

### Task registry (5 campos)
```
"label|desc_var|check_fn|apply_fn|status_fn"
```

### Patron check/status/apply
- `xxx::check()` — devuelve 0 si todo ok
- `xxx::status()` — string con issues (vacio si ok)
- `xxx::apply()` — wizard interactivo (modulos individuales)
- `xxx::run()` — submenu con registry de tareas (sub-aggregators: editors, browsers, security, etc.)

### Deteccion post-install
- `_xxx::is_installed()` — check en disco (dpkg, ficheros)
- `_xxx::session_ready()` — check en PATH/session
- Permite detectar "restart needed"

### Modulos siempre visibles
System essentials, Package managers, SSH, Developer tools, Software, GNOME siempre en menu principal. Sin status logging al inicio.

### gum wrappers
`gum::choose`, `gum::filter`, `gum::input` — todos capturan exit code y propagan SIGINT (130) con `exit 130`. NO usar `2>/dev/null` (gum renderiza UI en stderr).

### Sub-aggregators
Modulos agrupados (VPN, Passwords, Browsers, etc.) usan registry pattern con `gum::choose` o `gum::filter` segun cantidad.

### Repo compartido Mullvad
Browser y VPN comparten repo/GPG key. Ambos `remove()` verifican si el otro esta instalado antes de limpiar.

### Flatpak modules
Verifican `command -v flatpak` antes de instalar. Error claro si no disponible.

### GNOME patterns
- gsettings: checks via `gsettings get`, apply via `gsettings set || true`, reset via `gsettings reset || true`
- Custom keybindings: `dconf write` con path unico (`debian-setup-terminal`)
- Extensions: cache con `_extensions::refresh()`, gestion individual tipo VS Code wizard
- CSS marker: `/* debian-setup: vte padding */` para snippets propios en gtk.css
- GTK4 symlink: resolver a fichero regular antes de anadir CSS custom

### Package lists
- `packages/apt/*.txt` — listas APT (un paquete por linea, comentarios con #)
- `packages/deb/*.txt` — URLs de .deb directos
- `packages/vscode/extensions.txt` — extensiones VS Code (id|label)
- `packages/gnome/extensions.txt` — extensiones GNOME Shell (uuid|label)

### APT patterns
- `dpkg -l | grep '^ii'` en vez de `dpkg -s` (rc state)
- `hash -r` tras apt install/remove (bash command cache)
- `apt-get update` protegido con if/else (puede fallar con set -e)
- `chmod 644` tras `sudo mv` de mktemp (apt corre como `_apt`)
- `ui::flush_input` antes de sudo (gum deja escape sequences en /dev/tty)

### Ctrl+C
`trap 'printf "\n"; exit 130' INT` en entry point. Wrappers propagan exit 130.
