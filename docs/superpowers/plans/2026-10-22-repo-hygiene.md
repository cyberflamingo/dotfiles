# Repo Hygiene (pre-commit, CI, Dependabot) Implementation Record

**Goal:** Catch secrets, work terms and shell/workflow mistakes before they reach this public repo, locally and in CI.

**Approach:** Adapted from the setup of a separate reference repo (pinned pre-commit hooks, a CI job that re-runs them, SHA-pinned actions, Dependabot with a cooldown). Its company-internal scanner actions are not used. No devcontainer: this repo configures a host, it is not a project with a build environment.

**Status:** done and verified on branch `chezmoi-migration`.

## Files

| Path | Purpose |
|---|---|
| `.pre-commit-config.yaml` | Hooks, all pinned to commit SHAs (`pre-commit autoupdate --freeze`). |
| `.gitleaksignore` | Four reviewed false positives from the full-history scan. |
| `tests/denylist-check.sh` | Local hook: fails on any term from `~/.config/shell/denylist.txt`, prints `file:line` only, skips when the list is absent (CI). |
| `.github/workflows/lint.yaml` | CI: pre-commit on all files, plus a gitleaks scan of the whole history from a checksum-verified release binary. |
| `.github/dependabot.yml` | GitHub Actions updates, monthly, 7-day cooldown. |

## Hooks

| Hook | Scope |
|---|---|
| gitleaks, detect-private-key | all files (gitleaks scans staged changes locally, full history in CI) |
| check-merge-conflict, check-yaml (not `.tmpl`) | all files |
| check-executables-have-shebangs, check-shebang-scripts-are-executable | `tests/`, `local/bin/` (the Windows files and old bootstrap scripts have inconsistent modes) |
| shellcheck, shfmt (`-i 4 -bn -ci`) | `tests/` only until the rc files are cleaned up |
| actionlint | workflow files |
| denylist (local) | all files |
| no-commit-to-branch | `main` and `master`, local only (`SKIP` in CI) |

Not enabled on purpose: end-of-file and trailing-whitespace fixers (they would reformat the user's dotfiles), markdownlint (the plan documents are long tables and nested fences), prettier.

## Verification (2026-10-22)

- `pre-commit run --all-files`: all hooks pass.
- Full history, 334 commits: gitleaks found 4 matches, all reviewed as false positives (the public minisign key that verifies the dnscrypt resolver lists, and an Amazon redirect URL in an example comment of privoxy's stock action file). Recorded in `.gitleaksignore`; rescan reports no leaks.
- Self-test with a staged fake GitHub token and a denylisted term: both hooks fail as intended and print no secret text.
- Action SHAs and the gitleaks archive checksum were checked against upstream tags and release files; the pinned `pre-commit` and `uv` versions exist on PyPI.

## GitHub settings (not code)

Set in the repository settings:

- Secret scanning and push protection.
- Dependabot alerts.
- Branch protection on `main` (require the Lint workflow, no direct pushes).
- Code scanning default setup for the `actions` language (CodeQL does not analyse shell; shellcheck covers that).

## Maintenance

- Hook pins: `pre-commit autoupdate --freeze` about once a month, review the diff, run `pre-commit run --all-files`.
- Widen shellcheck and shfmt to the rc files once they are clean.
- Plan 2 adds a CI job that applies the dotfiles in a clean runner.
