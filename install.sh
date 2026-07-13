#!/usr/bin/env bash
# One-shot MacBook bootstrap.
#
#   Engineer:  curl -fsSL <raw-url>/install.sh | bash -s -- --profile engineer --fork <your-fork-url>
#   Staff:     curl -fsSL <raw-url>/install.sh | bash -s -- --profile staff
#
# Re-runnable and defensive. Prompts read from /dev/tty so it works under `curl | bash`.
set -euo pipefail

# ---- The canonical upstream repo everyone forks / staff clones ----------------------------
UPSTREAM_URL="git@github.com:hoptekai/bootstrap.git"
# ------------------------------------------------------------------------------------------

BOOTSTRAP_DIR="$HOME/.config/bootstrap"
PROFILE=""
FORK_URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift 2 ;;
    --fork)    FORK_URL="${2:-}"; shift 2 ;;
    --upstream) UPSTREAM_URL="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1"; exit 1 ;;
  esac
done

ask() { local prompt="$1" var; read -r -p "$prompt" var < /dev/tty; printf '%s' "$var"; }

[[ -n "$PROFILE" ]] || PROFILE="$(ask 'Profile [engineer/staff]: ')"
[[ "$PROFILE" == "engineer" || "$PROFILE" == "staff" ]] || { echo "profile must be engineer or staff"; exit 1; }

echo "==> Bootstrapping ($PROFILE)"

# 1. Homebrew (also pulls in Xcode Command Line Tools / git on a bare machine).
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

# 2. Clone the repo.
if [[ "$PROFILE" == "engineer" ]]; then
  [[ -n "$FORK_URL" ]] || FORK_URL="$(ask 'Your fork URL (git@github.com:you/bootstrap.git): ')"
  ORIGIN="$FORK_URL"
else
  ORIGIN="$UPSTREAM_URL"
fi

if [[ -d "$BOOTSTRAP_DIR/.git" ]]; then
  echo "==> Repo exists, pulling"
  git -C "$BOOTSTRAP_DIR" pull --ff-only || true
else
  echo "==> Cloning into $BOOTSTRAP_DIR"
  mkdir -p "$(dirname "$BOOTSTRAP_DIR")"
  git clone "$ORIGIN" "$BOOTSTRAP_DIR"
fi

if [[ "$PROFILE" == "engineer" ]] && ! git -C "$BOOTSTRAP_DIR" remote | grep -qx upstream; then
  git -C "$BOOTSTRAP_DIR" remote add upstream "$UPSTREAM_URL"
fi

echo "$PROFILE" > "$BOOTSTRAP_DIR/.profile"

if [[ "$PROFILE" == "staff" ]]; then
  # 3s. Staff: apps + baseline, no Nix.
  echo "==> Installing apps (brew bundle)"
  brew bundle --file="$BOOTSTRAP_DIR/staff/Brewfile"
  echo "==> Running optional package picker"
  "$BOOTSTRAP_DIR/bin/pick" staff || true
  brew bundle --file="$BOOTSTRAP_DIR/staff/Brewfile"
  echo "==> Applying security baseline"
  bash "$BOOTSTRAP_DIR/staff/defaults.sh"
  echo
  echo "Done. Manual step remaining: enable FileVault (System Settings -> Privacy & Security)."
  exit 0
fi

# 3e. Engineer: install Nix (Determinate installer, VANILLA upstream Nix — no --determinate).
if ! command -v nix >/dev/null 2>&1; then
  echo "==> Installing Nix (Determinate installer, upstream Nix)"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi
# shellcheck disable=SC1091
[[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]] \
  && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# 4. Render this user's overlay from the template (only edited file in the fork).
USERNAME="$(id -un)"
USERFILE="$BOOTSTRAP_DIR/users/$USERNAME.nix"
if [[ ! -f "$USERFILE" ]]; then
  echo "==> Creating users/$USERNAME.nix"
  FULL_NAME="$(ask 'Full name (for git): ')"
  GIT_EMAIL="$(ask 'Git email: ')"
  echo "Paste your 1Password SSH PUBLIC key (ssh-ed25519 ...), used to sign commits:"
  SSH_PUBKEY="$(ask '> ')"
  sed -e "s|__FULL_NAME__|$FULL_NAME|" \
      -e "s|__GIT_EMAIL__|$GIT_EMAIL|" \
      -e "s|__ONEPASSWORD_SSH_PUBLIC_KEY__|$SSH_PUBKEY|" \
      "$BOOTSTRAP_DIR/users/_template.nix" > "$USERFILE"
  git -C "$BOOTSTRAP_DIR" add "users/$USERNAME.nix"
  git -C "$BOOTSTRAP_DIR" commit -m "Add overlay for $USERNAME" || true
fi

# 5. Optional packages.
echo "==> Running optional package picker"
"$BOOTSTRAP_DIR/bin/pick" engineer || true

# 6. First build (nix-darwin not yet installed, so bootstrap it via `nix run`).
echo "==> First darwin-rebuild switch (#$USERNAME) — you'll be asked for your password"
nix run nix-darwin -- switch --flake "$BOOTSTRAP_DIR#$USERNAME"

cat <<EOF

Done. Manual steps remaining (see README):
  - Enable FileVault (System Settings -> Privacy & Security)
  - Turn on the 1Password SSH agent (1Password -> Settings -> Developer)
  - Push your overlay commit to your fork:  git -C $BOOTSTRAP_DIR push origin
Everyday use: 'boot update' (pull fleet changes), 'boot pick', 'boot doctor'.
EOF
