{ inputs, ... }:

{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "stefan";
  };

  homebrew = {
    enable = true;

    taps = [
      "sst/tap"
    ];

    brews = [
      "mas"
      "opencode"
    ];

    # Cask
    casks = [
      "1password"
      "betterdisplay"
      "cleanshot"
      "discord"
      "docker"
      "firefox"
      "ghostty"
      "google-chrome"
      "linearmouse"
      "moonlight"
      "obs"
      "obsidian"
      "postman"
      "raycast"
      "visual-studio-code"
      "zed"
      "zen"
      "rectangle"
    ];

    # Applications from Apple Store
    masApps = {
      "Infuse • Video Player" = 1136220934;
      "Tailscale" = 1475387142;
      "TickTick:To-Do List, Calendar" = 966085870;
    };

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };

}
