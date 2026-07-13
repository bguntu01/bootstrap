# bootstrap

Get a new MacBook to a fully-configured state with one command. Two profiles:

- **engineer** — full Nix dev environment: [nix-darwin] (declarative macOS system config +
  security baseline), [Home Manager] (shell/dotfiles/CLI tools), and [devbox] for
  per-project toolchains.
- **staff** — apps only (Slack, Chrome, Spotify, …). **No Nix** — just Homebrew + a light
  security baseline.

Both share one Homebrew app list, so fleet apps are maintained in a single place.

---

## Quick start

### Engineers

1. **Enable FileVault** — System Settings → Privacy & Security → FileVault. (Can't be done
   declaratively; do it first.)
2. **Join 1Password** (Business) and accept the shared **Eng** vault.
3. **Turn on the 1Password SSH agent** — 1Password → Settings → Developer → *Use the SSH
   agent*. Create/choose an SSH key; add its **public** key to
   [GitHub → Settings → SSH keys](https://github.com/settings/keys) as both an
   *Authentication* and a *Signing* key.
4. **Fork this repo** to your own GitHub account.
5. **Run the installer** (paste your fork's clone URL):

   ```sh
   curl -fsSL https://raw.githubusercontent.com/hoptekai/bootstrap/main/install.sh \
     | bash -s -- --profile engineer --fork git@github.com:YOU/bootstrap.git
   ```

   It installs Homebrew + Nix (Determinate installer, upstream Nix), clones your fork to
   `~/.config/bootstrap`, generates `users/<you>.nix` from the template (asking for your
   name, git email, and 1Password signing key), runs the optional-package picker, and does
   the first `darwin-rebuild switch`.
6. **Push your overlay:** `git -C ~/.config/bootstrap push origin`.

### Staff

1. **Enable FileVault** (as above).
2. **Run the installer:**

   ```sh
   curl -fsSL https://raw.githubusercontent.com/hoptekai/bootstrap/main/install.sh \
     | bash -s -- --profile staff
   ```

   Installs Homebrew, the shared apps, your optional picks, and the security baseline.

---

## Everyday use (engineers)

The `boot` helper is on your PATH:

| Command          | What it does                                            |
|------------------|---------------------------------------------------------|
| `boot update`    | pull fleet changes from upstream + bump nixpkgs + switch |
| `boot pull`      | pull fleet changes from upstream + switch                |
| `boot switch`    | apply your current config                                |
| `boot pick`      | choose optional packages (gum checklist)                 |
| `boot add <cask>`| add a Homebrew cask and switch                           |
| `boot doctor`    | sanity-check Nix / brew / 1Password / SSH / upstream     |

`just` recipes mirror these for working inside the repo.

## How it fits together (fork-based workflow)

The **canonical upstream** repo owns all shared files (`hosts/`, `home/`, `modules/`,
`packages/`). You **fork** it, and the only file you edit is your generated
`users/<username>.nix`. Because everyone touches only their own overlay, pulling fleet-wide
changes (`boot update`) is (near-)conflict-free. Your machine is reproducible from your fork.

```
install.sh              one-shot bootstrap (--profile engineer|staff)
flake.nix               darwinConfigurations, auto-discovered from users/*.nix
hosts/common.nix        shared system config
modules/
  macos-defaults.nix    security baseline + system defaults
  homebrew.nix          casks/brews via nix-darwin (imports the shared list)
home/common.nix         shared Home Manager: zsh, git+signing, tools, editor
users/_template.nix     rendered into users/<you>.nix by install.sh
packages/
  casks-shared.nix      GUI apps + fast-moving CLIs (single source of truth)
  optional.list         pickable optional packages (one line each)
staff/
  Brewfile              no-Nix app list (mirrors casks-shared.nix)
  defaults.sh           no-Nix security baseline
templates/devbox.json   starter to drop into projects
bin/{boot,pick}         helpers
```

## Secrets & signing (1Password)

- SSH keys are served by the **1Password SSH agent** — they never touch disk.
- Git commits are **signed** via 1Password (`op-ssh-sign`, wired in `home/common.nix`).
- Pull project secrets with `op read`, e.g.
  `export DATABASE_URL=$(op read 'op://Eng/my-project/database_url')`, or template a `.env`
  with `op inject`. See `templates/devbox.json`.

## Per-project environments (devbox)

Machine-level tools come from this repo; **per-project language versions come from devbox**.
Drop `templates/devbox.json` into a project and `direnv allow` — the shell auto-activates.
No global Node/Python/Go is installed on purpose.

## Maintaining the fleet (upstream maintainers)

- **Add an always-installed app:** one line in `packages/casks-shared.nix` (and mirror it in
  `staff/Brewfile`). Everyone gets it on their next `boot update`.
- **Add a pickable optional app:** one line in `packages/optional.list`.
- **Change fleet-wide Claude Code guidance:** edit `claude/common.md`. It's symlinked to
  `~/.claude/common.md` on every switch; each engineer's own `~/.claude/CLAUDE.md` imports it
  via `@common.md` and is seeded once (never overwritten), so personal tweaks are safe.
- **Bump everything (nixpkgs):** `nix flake update` + commit; the fleet picks it up on
  `boot update`.

## Notes

- Fast-moving apps (Claude Code, etc.) live in **Homebrew**, not the nixpkgs pin, so they
  stay current.
- No MDM (Jamf/Kandji) — this repo is the security baseline.
- FileVault is a manual step; it can't be enabled declaratively.

[nix-darwin]: https://github.com/LnL7/nix-darwin
[Home Manager]: https://github.com/nix-community/home-manager
[devbox]: https://www.jetify.com/devbox
