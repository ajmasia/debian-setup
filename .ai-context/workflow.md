# Workflow and Releases

## Daily development

1. Always work on `develop`
2. Frequent commits using semantic commits (`feat`, `fix`, `refactor`, etc.)
3. Push to `origin/develop` as needed

## Safe working strategy

- **Baseline commit** before starting any work — ensures a clean rollback point
- **One commit per completed feature/fix** — each commit is a safe rollback point
- **If something breaks**, `git checkout` to revert to the last known good commit instead of trying to debug a broken state
- **Always ask before moving to the next task** — let the user validate and confirm before proceeding

## Release cycle

When changes on `develop` are ready for release:

1. `chore: bump version to X.Y.Z` — update `VERSION`
2. `docs: update README and CHANGELOG for vX.Y.Z` — update `CHANGELOG.md` and `README.md` (version badge)
3. On `main`: `git merge develop` (merge commit: "Merge branch 'develop'")
4. Push both branches: `git push origin develop main`

## CHANGELOG

[Keep a Changelog](https://keepachangelog.com/) format. Sections: `Added`, `Changed`, `Fixed`.

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- **Feature Name** -- concise description

### Changed
- **Feature Name** -- what changed

### Fixed
- Description of the fix
```

## VERSION

`VERSION` file in root with semver (`MAJOR.MINOR.PATCH`), single line. Read by the entry point and the installer.

## Remote

- Origin: Self-hosted Gitea (`git.qwertee.link`)
- Protocol: SSH (`ssh://gitea@git.qwertee.link:2022/...`)
