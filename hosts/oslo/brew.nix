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

    brews = [
      "mas"
    ];

    casks = [
      "1password"
      "cleanshot"
      "docker"
      "ghostty"
      "obs"
      "obsidian"
      "skype"
      "zen-browser"
    ];

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
