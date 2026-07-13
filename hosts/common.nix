# Shared, user-agnostic system config for every engineer machine.
# Centrally owned upstream — engineers pull changes here, they do not edit it.
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Determinate installs the daemon; don't let nix-darwin try to manage the nix binary.
  nix.enable = false;

  # Fleet-wide system packages stay minimal on purpose:
  #   - CLI dev tools live in Home Manager (home/common.nix)
  #   - per-project language runtimes live in devbox
  environment.systemPackages = with pkgs; [ git ];

  programs.zsh.enable = true;

  # Bump deliberately; see nix-darwin release notes before changing.
  system.stateVersion = 5;
}
