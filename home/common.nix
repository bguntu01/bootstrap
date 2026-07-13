# Shared Home Manager config imported by every user overlay (users/<username>.nix).
# Centrally owned upstream. Personal identity (name/email/signing key) lives in the overlay.
{ pkgs, config, lib, ... }:
let
  # 1Password serves SSH keys from its agent — keys never touch disk.
  onePasswordAgentSock =
    "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  # Signer shipped by the 1Password desktop app for SSH-based git commit signing.
  opSshSign = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
in
{
  home.stateVersion = "24.05";

  # Machine-level CLI toolset. NO global Node/Python/Go — devbox owns per-project runtimes.
  home.packages = with pkgs; [
    gh
    ripgrep
    fd
    bat
    eza
    fzf
    jq
    tmux
    gum        # powers the `boot pick` package selector
    devbox     # per-project environments
  ];

  home.sessionVariables = {
    EDITOR = "zed --wait";
    VISUAL = "zed --wait";
    SSH_AUTH_SOCK = onePasswordAgentSock;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    # Put the repo's `boot` / `pick` helpers on PATH.
    initContent = ''
      export PATH="$HOME/.config/bootstrap/bin:$PATH"
    '';
  };

  programs.starship.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;   # fast, cached devbox/nix shell activation
  };

  # Claude Code: fleet-wide guidance in ~/.claude/common.md (managed — refreshed on switch),
  # imported by the user's own ~/.claude/CLAUDE.md (seeded once, then owned by the user).
  home.file.".claude/common.md".source = ../claude/common.md;
  home.activation.seedClaudeMd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.claude/CLAUDE.md" ]; then
      $DRY_RUN_CMD install $VERBOSE_ARG -m 0644 -D ${../claude/seed-claude.md} "$HOME/.claude/CLAUDE.md"
    fi
  '';

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      # Commit signing via the 1Password SSH agent (key + signByDefault set in the overlay).
      gpg.format = "ssh";
      gpg.ssh.program = opSshSign;
      core.editor = "zed --wait";
    };
    # user.name / user.email / signing key come from the per-user overlay.
  };
}
