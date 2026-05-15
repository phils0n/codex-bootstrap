#!/usr/bin/env bash
# Public bootstrap for phils0n's private Codex dotfiles.
# Fetch this on a new Mac, authenticate GitHub, then apply chezmoi.

set -euo pipefail

export HOMEBREW_NO_AUTO_UPDATE="${HOMEBREW_NO_AUTO_UPDATE:-1}"
export HOMEBREW_NO_ENV_HINTS="${HOMEBREW_NO_ENV_HINTS:-1}"
export HOMEBREW_NO_INSTALL_CLEANUP="${HOMEBREW_NO_INSTALL_CLEANUP:-1}"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

info()    { printf '%b\n' "${CYAN}[bootstrap]${NC} $*"; }
success() { printf '%b\n' "${GREEN}[✓]${NC}          $*"; }
warn()    { printf '%b\n' "${YELLOW}[warn]${NC}       $*"; }
error()   { printf '%b\n' "${RED}[error]${NC}      $*"; exit 1; }
step()    { printf '\n%b\n' "${BOLD}── $* ──${NC}"; }

DOTFILES_OWNER="${DOTFILES_OWNER:-phils0n}"
DOTFILES_REPO="${DOTFILES_REPO:-dotfiles}"
DOTFILES_SSH="git@github.com:${DOTFILES_OWNER}/${DOTFILES_REPO}.git"

run_quick() {
  local seconds="$1"
  shift
  perl -e 'alarm shift @ARGV; exec @ARGV' "$seconds" "$@" &>/dev/null
}

ensure_homebrew() {
  if command -v brew &>/dev/null; then
    success "Homebrew $(brew --version | head -1 | awk '{print $2}')"
    return 0
  fi

  step "Installing Homebrew"
  warn "Homebrew install may ask for your Mac password."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  command -v brew &>/dev/null || error "Homebrew install finished, but brew is not in PATH"
  success "Homebrew installed"
}

brew_ensure() {
  local formula="$1"
  local binary="$2"
  local label="$3"

  if command -v "$binary" &>/dev/null; then
    success "$label present"
  else
    info "Installing $label..."
    brew install "$formula"
    hash -r
    command -v "$binary" &>/dev/null && success "$label ready" || error "$label install failed"
  fi
}

github_auth_ok() {
  command -v gh &>/dev/null && run_quick 5 gh auth status
}

github_ssh_ok() {
  local out
  out=$(ssh -T git@github.com -o ConnectTimeout=8 -o BatchMode=yes 2>&1 || true)
  printf '%s\n' "$out" | grep -q "successfully authenticated"
}

ensure_github_auth() {
  step "GitHub access"

  if github_auth_ok && github_ssh_ok; then
    success "GitHub auth and SSH ready"
    return 0
  fi

  if [ "${BOOTSTRAP_SKIP_AUTH:-}" = "1" ]; then
    warn "BOOTSTRAP_SKIP_AUTH=1 — skipping GitHub browser auth"
    return 0
  fi

  if ! github_auth_ok; then
    info "Opening GitHub login. Choose SSH when prompted."
    gh auth login -h github.com --web --git-protocol ssh
  fi

  gh auth setup-git || true

  if ! github_ssh_ok; then
    warn "GitHub SSH is not ready yet. gh will try to create/upload an SSH key."
    gh auth refresh -h github.com -s admin:public_key || true
    gh ssh-key list &>/dev/null || true
    github_ssh_ok || warn "SSH still not verified. If clone fails, run: gh auth login -h github.com --web --git-protocol ssh"
  fi
}

ensure_chezmoi() {
  if command -v chezmoi &>/dev/null; then
    success "chezmoi $(chezmoi --version | awk '{print $3}' | head -1)"
  else
    brew_ensure "chezmoi" "chezmoi" "chezmoi"
  fi
}

apply_dotfiles() {
  step "Applying Codex dotfiles"

  if [ "${BOOTSTRAP_SKIP_AUTH:-}" = "1" ]; then
    export SETUP_SKIP_AUTH=1
  fi

  if github_ssh_ok; then
    chezmoi init --apply --ssh "$DOTFILES_OWNER"
  else
    warn "SSH not verified; trying explicit repo URL anyway."
    chezmoi init --apply "$DOTFILES_SSH"
  fi
}

step "Codex bootstrap"

ensure_homebrew
brew_ensure "git" "git" "Git"
brew_ensure "node" "node" "Node.js"
brew_ensure "gh" "gh" "GitHub CLI"
ensure_github_auth
ensure_chezmoi
apply_dotfiles

echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  Bootstrap complete${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next upgrades:"
echo "  codex-upgrade"
echo ""
