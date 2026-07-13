# macOS security baseline + sensible system defaults (engineer profile).
# There is no MDM in front of these machines, so this module IS the baseline.
# NOTE: FileVault cannot be enabled declaratively — it stays a README checklist step.
{ ... }:
{
  # Application-layer firewall on, in stealth mode.
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;   # don't respond to probes
  };

  system.defaults = {
    # Require a password shortly after sleep / screensaver.
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 5;
    };

    loginwindow.GuestEnabled = false;

    # Screenshots out of the way of the Desktop.
    screencapture.location = "~/Screenshots";

    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;  # key repeat instead of accent popup
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };

    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      FXEnableExtensionChangeWarning = false;
    };

    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false;
    };

    trackpad.Clicking = true;  # tap to click
  };
}
