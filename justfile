# Task runner for the bootstrap repo. `just <recipe>`; most are also exposed via `boot`.
# Engineer profile assumed for nix recipes.

user := `id -un`
dir  := justfile_directory()

# List recipes.
default:
    @just --list

# Apply the current config.
switch:
    sudo darwin-rebuild switch --flake "{{dir}}#{{user}}"

# Pull fleet-wide changes from upstream, then switch.
pull:
    git pull --rebase upstream main
    @just switch

# Pull upstream + bump the nixpkgs pin, then switch.
update:
    git pull --rebase upstream main
    nix flake update
    @just switch

# Choose optional packages.
pick:
    "{{dir}}/bin/pick" engineer

# Add a Homebrew cask and switch.
add cask:
    "{{dir}}/bin/boot" add "{{cask}}"

# Sanity-check the environment.
doctor:
    "{{dir}}/bin/boot" doctor

# Build the full closure without switching (safe verification).
check:
    nix flake check
    darwin-rebuild build --flake "{{dir}}#{{user}}"
