{ pkgs, inputs, ... }:

{
  imports = [
    ../../modules/darwin
    ./home.nix
    ./brew.nix
  ];

  # This is usually in hardware-configuration, and is required
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Machine Name
  networking.hostName = "oslo";

  # Set your time zone.
  time.timeZone = "Europe/Belgrade";

  # User setup
  users.users.stefan = {
    name = "stefan";
    home = "/Users/stefan";
    description = "Stefan Bondzulic";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1UcE51oQhUbXEdGHvlJMSmKJQCVsP7xt5Tmj3+m4yN stefanbondzulic@pm.me"
    ];
    packages = [
      inputs.home-manager.packages.${pkgs.system}.default
    ];
  };

  environment = {
    systemPath = [
      "/opt/homebrew/bin"
    ];

    systemPackages = with pkgs; [];
  };

  system.defaults = {
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

  system.stateVersion = 6;
}

