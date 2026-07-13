# Single source of truth for GUI apps + fast-moving CLIs installed via Homebrew.
# Consumed by BOTH profiles:
#   - engineers: modules/homebrew.nix imports this into nix-darwin's homebrew.*
#   - staff:     staff/Brewfile mirrors this list (keep them in sync)
#
# Why Homebrew and not nixpkgs: these should track upstream and not be frozen behind the
# flake pin. Adding an always-installed app = one line here. Optional/pick-your-own apps
# live in packages/optional.list instead.
{
  casks = [
    "1password"          # password manager + SSH agent
    "1password-cli"      # `op` + `op-ssh-sign` for secrets and git signing
    "google-chrome"
    "slack"
    "zed"                # default editor
  ];

  brews = [
    # Claude Code — ships fast, so Homebrew keeps it current independent of the nixpkgs pin.
    # If this isn't in homebrew-core in your region yet, add the appropriate tap in
    # modules/homebrew.nix (homebrew.taps) and adjust the name.
    "claude-code"
  ];
}
