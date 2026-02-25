# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Your Application Development Guidelines

The `.ai-context/` directory contains all essential project context documentation. Always consult these files before starting any work:

### Project architecture

- @./.ai-context/architecture.md

### Code patterns and conventions

- @./.ai-context/patterns.md

### Module hierarchy and package lists

- @./.ai-context/modules.md

### Library reference

- @./.ai-context/libraries.md

### Git conventions

- @./.ai-context/git.md

### Workflow and releases

- @./.ai-context/workflow.md

## Overview

Bash CLI to automate post-installation tasks on Debian 13 (Trixie). Interactive menu-driven tool using [gum](https://github.com/charmbracelet/gum) for UI.

## Running

```bash
./debian-setup              # Interactive menu
./debian-setup --search     # Global flat search across all tasks
./debian-setup -si          # Search only uninstalled items
./debian-setup -sr          # Search only installed items
./debian-setup --version    # Show version (from VERSION file)
./debian-setup --update     # Git pull --ff-only
```

No test framework, linter config, CI, or build step. The tool runs directly as a Bash script.

## Stack

- **Shell**: Bash with `set -euo pipefail`
- **UI**: [gum](https://github.com/charmbracelet/gum) (Charm) — hard dependency
- **Palette**: Catppuccin Mocha (ANSI + hex constants in `src/lib/colors.sh`)
- **Logs**: XDG compliant — `$XDG_STATE_HOME/debian-setup/logs/YYYY-MM-DD.log`

## Conventions

- **Language**: Code and CLI messages in English, user communication in Spanish
- **Commits**: Semantic commits (feat/fix/chore/refactor). NO references to Claude AI. NO Co-Authored-By
- **Signed commits**: SSH signing with ED25519 (configured in git config)
- **Branches**: `develop` (work), `main` (releases)
- **Namespaces**: 2 levels with `::` (log::info, ui::header, health::run). NEVER 3 levels
- **Private helpers**: `_` prefix (e.g. `_git_config::is_installed()`)
- **Load guards**: `[[ -n "${_LIB_X_LOADED:-}" ]] && return 0` in every sourced file
- **Labels**: Title Case ("Configure SSH Keys", "Configure Build Essentials")
- **Sourcing order**: colors > xdg > log > system > gum > ui > apt (lib) > menu > modules

