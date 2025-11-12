{ pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
    ./home.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [
    "nct6775"
    "mitigations=of"
    "hid_playstation"
    "hidp"
    "xpad"
  ];

  services.udev.packages = [ pkgs.game-devices-udev-rules ]; # Permissions for controllers

  # Machine Name
  networking.hostName = "endor";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable Bluetooth with extended codec/controller support
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Experimental = true; # Helps with auto-connect and multi-device
        KernelExperimental = true;
      };
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Belgrade";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Assuming KDE Plasma is already enabled; if not, add this:
  services.desktopManager.plasma6.enable = true;

  # Enable a display manager if not already set (SDDM is recommended for KDE and supports Wayland sessions)
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true; # Ensures Wayland support for Niri

  # Enable Niri WM
  programs.niri.enable = true;

  # Optional: Ensure XDG portals are enabled for better app compatibility (e.g., file pickers, screencasting)
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gtk
    pkgs.xdg-desktop-portal-gnome
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # User setup
  users.users.bondzula = {
    isNormalUser = true;
    description = "Stefan Bondzulic";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    packages = [
      inputs.home-manager.packages.${pkgs.system}.default
    ];
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-high-quality.lua" ''
          bluez_monitor.properties = {
            ["bluez5.enable-msbc"] = true,
            ["bluez5.enable-sbc-xq"] = true,
            ["bluez5.enable-lc3"] = true,
            ["bluez5.hfphsp-backend"] = "native",
            ["bluez5.autoswitch-to-headset-profile"] = false,
            ["bluez5.headset-roles"] = "[hsp_hs hsp_ag hfp_hf hfp_ag]",
            ["bluez5.roles"] = "[a2dp_sink a2dp_source bap_sink bap_source]",
          }
        '')
      ];
    };
  };

  # 1Password setup
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "bondzula" ];
  };

  # CoolerControl
  programs.coolercontrol.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    lm_sensors
    # Quickshell and its dependencies plus config in noctalia
    quickshell
    gpu-screen-recorder
    brightnessctl
    ddcutil
    cliphist
    kdePackages.qt6ct
    nwg-look
    adw-gtk3
    inputs.noctalia.packages.${system}.default

    gnome-keyring
    xwayland-satellite
    swayidle
  ];

  # List services that you want to enable:
  nixosModules = {
    hardware.has.amd.gpu = true;

    zsh.enable = true;
    gaming.enable = true;
    podman.enable = true;
    vm.enable = true;
  };

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    allowSFTP = true;
  };

  # Enable Tailscale
  services.tailscale = {
    enable = true;
    port = 41641;
    useRoutingFeatures = "client";
    extraUpFlags = [ "--ssh" ];
  };

  # Keep SoC/device power profiles healthy for wireless controllers/audio
  services.power-profiles-daemon.enable = true;

  system.stateVersion = "25.05";
}
