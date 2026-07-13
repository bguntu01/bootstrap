# Homebrew, managed declaratively by nix-darwin (engineer profile).
# GUI apps and fast-moving CLIs live here — NOT in the nixpkgs pin — so they track upstream.
{ username, ... }:
let
  shared = import ../packages/casks-shared.nix;
in
{
  # nix-homebrew owns the brew installation itself.
  nix-homebrew = {
    enable = true;
    enableRosetta = true;   # allow x86_64 casks on Apple Silicon
    user = username;        # owner of the Homebrew prefix
    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;       # keep casks/brews current (e.g. Claude Code) on every switch
      cleanup = "zap";      # converge the fleet: remove anything not declared
    };

    # Single source of truth shared with the staff Brewfile.
    casks = shared.casks;
    brews = shared.brews;
    # Per-user optional casks are appended from users/<username>.nix (see `boot pick`).
  };
}
