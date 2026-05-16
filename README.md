# Codex Bootstrap

One-command setup for Adrian's Codex workflow: install tools, apply dotfiles, start projects, implement issues, review, create fix issues, repeat, and ship.

## 1. New Machine Setup

Run on a new Mac:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/phils0n/codex-bootstrap/main/bootstrap.sh)"
```

The bootstrap script:

- installs Homebrew if missing
- installs `git`, `node`, `gh`, and `chezmoi`
- prompts for GitHub auth so the private dotfiles repo can be cloned
- applies `git@github.com:phils0n/dotfiles.git`
- installs Codex workflow helpers into `~/bin`
- configures `~/.codex/AGENTS.md`, skills, RTK, and Caveman mode
- prompts for Codex, GitHub CLI, and Docker Sandboxes auth

After install, verify:

```bash
codex-workflow --help
codex --version
gh auth status
sbx-yolo --check
```

If Docker Sandboxes is not ready yet, run:

```bash
sbx login
```

## 2. Upgrade Existing Machine

Pull latest dotfiles and reapply setup:

```bash
codex-upgrade
```

Use this after workflow helper changes.

## 3. Command Map

| Command | Purpose |
|---|---|
| `codex-workflow --help` | Show the full command menu |
| `codex-kickoff` | Start repo setup, grilling, spec, and issue creation |
| `codex-afk` | Implement ready issue files with one subagent at a time |
| `codex-review` | Review completed work and save findings |
| `codex-fix-issues` | Convert review findings into ready fix issues |
| `codex-upgrade` | Pull and apply latest dotfiles |
| `sbx-yolo --check` | Verify Docker Sandboxes is usable |
| `yolo-kickoff` | Start sandboxed full-auto Codex environment |

## 4. Start a New Project

Create or open the project folder:

```bash
mkdir my-project
cd my-project
git init
```

Start the workflow:

```bash
codex-kickoff
```

Optional with initial idea:

```bash
codex-kickoff "build a EuroBonus award availability finder"
```

Expected output from the kickoff phase:

- repo `AGENTS.md` or equivalent project workflow config
- `docs/agents/` setup
- `CONTEXT.md` or domain docs when needed
- `docs/specs/*.md`
- `.scratch/<feature>/PRD.md`
- `.scratch/<feature>/issues/*.md`

If Codex asks questions, answer them in the same session. It should resolve obvious MVP decisions itself and only ask for user-dependent choices.

## 5. Implement Issues

After kickoff has created issue files:

```bash
codex-afk
```

Default issue search:

```text
.scratch/*/issues/*.md
issues/*.md
```

For a specific issue folder:

```bash
codex-afk --issues ".scratch/eurobonus-finder-mvp/issues/*.md"
```

What `codex-afk` does:

- starts Codex with an AFK implementation prompt
- uses subagents one at a time
- each subagent handles exactly one ready issue
- each subagent reports changed files and checks run
- repeats until `NO MORE TASKS`

It should not push or publish.

## 6. Review Completed Work

After AFK says no tasks remain:

```bash
codex-review
```

`codex-review` reviews against:

- `docs/specs/*.md`
- `.scratch/*/PRD.md`
- `.scratch/*/issues/*.md`

It checks for:

- bugs
- missing acceptance criteria
- test gaps
- security issues
- data model and migration problems
- architecture problems
- runtime/build caveats

By default it writes:

```text
ralph/review-findings.md
```

That file is the handoff artifact for the next session.

Pure read-only review:

```bash
codex-review --no-save
```

Custom review output:

```bash
codex-review --out ralph/review-findings-round-2.md
```

## 7. Turn Review Findings Into Fix Issues

If review finds problems:

```bash
codex-fix-issues
```

Default behavior:

- uses `ralph/review-findings.md` if present
- otherwise runs a fresh review-to-issues pass
- writes fix issues under `.scratch/<feature>/review-fixes/`
- creates one `ready-for-agent` issue per actionable finding
- does not implement code

Explicit review file:

```bash
codex-fix-issues --from-file ralph/review-findings.md
```

Then implement the fix issues:

```bash
codex-afk --issues ".scratch/*/review-fixes/*.md"
```

Review again:

```bash
codex-review
```

Repeat until review has no blocking findings.

## 8. Full Loop

Typical project loop:

```bash
codex-kickoff
codex-afk
codex-review
codex-fix-issues
codex-afk --issues ".scratch/*/review-fixes/*.md"
codex-review
```

If the final review still finds issues, repeat:

```bash
codex-fix-issues
codex-afk --issues ".scratch/*/review-fixes/*.md"
codex-review
```

## 9. Git Save Points

Use git as the safety net. If the repo is not initialized yet:

```bash
git init
```

Before committing, inspect:

```bash
git status --short
git diff
```

Run checks:

```bash
npm run lint
npm test
npm run test:e2e
npm run build
```

Commit after a clean review/fix pass:

```bash
git add .
git commit -m "feat: implement MVP"
```

Create a private GitHub repo and push:

```bash
gh repo create my-project --private --source=. --remote=origin --push
```

## 10. Ship

Before shipping:

```bash
codex-review
```

Then start a shipping review:

```bash
codex -p local "Use the shipping-and-launch skill. Prepare this project for release. Review docs/specs/*.md, .scratch/*/PRD.md, issue files, README, env requirements, deploy steps, monitoring, rollback, and unresolved review findings. Do not deploy without asking."
```

Minimum ship checklist:

- final `codex-review` has no Critical/High findings
- tests and build pass
- `.env.example` is complete
- secrets are not committed
- database migrations are documented and tested
- README explains local run and production setup
- deploy target is chosen
- rollback plan exists

## 11. Sandbox Flow

Use sandbox mode when you want a stronger safety boundary:

```bash
sbx-yolo --check
yolo-kickoff
```

Inside the sandbox:

```bash
codex --profile yolo
$kickoff
```

For normal local agent work, use:

```bash
codex-kickoff
codex-afk
codex-review
```

## 12. Troubleshooting

Show all commands:

```bash
codex-workflow --help
```

GitHub auth:

```bash
gh auth login -h github.com --web --git-protocol ssh
gh auth status
ssh -T git@github.com
```

Codex auth:

```bash
codex login
```

Docker Sandboxes:

```bash
sbx login
sbx-yolo --check
```

Dotfiles:

```bash
chezmoi status
chezmoi diff
chezmoi update --apply
```

## 13. One-Line Reference

New machine:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/phils0n/codex-bootstrap/main/bootstrap.sh)"
```

New project:

```bash
codex-kickoff
```

Build:

```bash
codex-afk
```

Review and fix:

```bash
codex-review
codex-fix-issues
codex-afk --issues ".scratch/*/review-fixes/*.md"
codex-review
```

Upgrade workflow:

```bash
codex-upgrade
```
