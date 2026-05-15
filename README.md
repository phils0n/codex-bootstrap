# Codex Bootstrap

Public first-hop bootstrap for `phils0n/dotfiles`.

Run on a new Mac:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/phils0n/codex-bootstrap/main/bootstrap.sh)"
```

What it does:

- Installs Homebrew if missing.
- Installs or updates `git`, `node`, `gh`, and `chezmoi`.
- Prompts for GitHub login before cloning the private dotfiles repo.
- Applies `git@github.com:phils0n/dotfiles.git` with chezmoi.
- The dotfiles setup then prompts for Codex, GitHub CLI, and Docker Sandboxes logins.

After first install:

```bash
codex-upgrade
```
