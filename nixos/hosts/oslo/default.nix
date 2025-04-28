{ pkgs, lib, config, inputs, outputs, ... }:

{
  imports = [
    ../../modules/darwin/default.nix
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # User setup
  users.users.stefan = {
    name = "stefan";
    home = "/Users/stefan";
  };

  # Home Manager setup
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      stefan = ../../../home/hosts/oslo/stefan.nix;
    };
  };

  environment = {
    systemPath = [
      "/opt/homebrew/bin"
    ];

    systemPackages = with pkgs; [
      # This should be left as a system package
      neovim
      git
      curl
      wget

      # Transfered as part of default cli apps
      rsync
      tealdeer
      wakeonlan

      # Part of Fonts module
      nerd-fonts.jetbrains-mono

      # Refactor this
      ansible
      mysql84
      lazygit
      lazydocker
      cmake
      markdownlint-cli2
      nodePackages.prettier
      languagetool-rust
      nodejs_20
      pnpm
      go
      magic-wormhole
      uv
      caddy
    ];
  };

  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = true;

    # User owning the Homebrew prefix
    user = "stefan";
  };

  homebrew = {
    enable = false;

    brews = [
      "mas"
      "exercism"
    ];

    casks = [
      "1password"
      "cleanshot"
      "docker"
      "firefox"
      "monitorcontrol"
      "obsidian"
      "raycast"
      "skype"
      "zen-browser"
      "google-chrome"
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

  system.defaults = {
    # Dock settings
    dock = {
      autohide = true;
      show-recents = false;
      persistent-apps = [
        "/Applications/Zen Browser.app"
        "/Applications/Ghostty.app"
        "/Applications/Obsidian.app"
        "/Applications/TickTick.app"
      ];
    };

    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      InitialKeyRepeat = 15;
      KeyRepeat = 1;
      "com.apple.mouse.tapBehavior" = 1;
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
    };

    WindowManager = {
      StandardHideDesktopIcons = true;
      StandardHideWidgets = true;
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}

