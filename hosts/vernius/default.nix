{ modulesPath, pkgs, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix") # Substitute for hardware-config.nix when working with proxmox LXC
    ../../modules/nixos
  ];

  # LXC container do not have permissions for creating sandbox
  nix.settings = {
    sandbox = false;
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  nixpkgs = {
    # You can add overlays here
    overlays = [
      (final: prev: {
        jellyfin-ffmpeg = prev.jellyfin-ffmpeg.override {
          # Exact version of ffmpeg_* depends on what jellyfin-ffmpeg package is using.
          # In 24.11 it's ffmpeg_7-full.
          # See jellyfin-ffmpeg package source for details
          ffmpeg_7-full = prev.ffmpeg_7-full.override {
            withMfx = false; # This corresponds to the older media driver
            withVpl = true; # This is the new driver
            withUnfree = true;
          };
        };
      })
    ];
  };

  # LXC specific settings, provided by the above import
  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
  };

  ## Arc drivers & VA-API
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # iHD: mandatory for Arc
      intel-compute-runtime # OpenCL: HDR tone-mapping & subtitles
      vpl-gpu-rt # QSV on 11th gen or newer
      intel-ocl # OpenCL support
    ];
  };

  ## environment tweaks
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    LIBVA_DRIVERS_PATH = "${pkgs.intel-media-driver}/lib/dri";
  };

  # Set your time zone.
  time.timeZone = "Europe/Belgrade";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Setup users
  users = {
    users.bondzula = {
      initialHashedPassword = "$y$j9T$lTYSuKE.0BiJazE5fJ72B0$XMEo8mlRwfxuT6Q8bDielkRNGIFy.To2qsEYw7hbIm/";
      isNormalUser = true;
      description = "Stefan Bondzulic";
      extraGroups = [
        "wheel"
        "video"
        "render"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1UcE51oQhUbXEdGHvlJMSmKJQCVsP7xt5Tmj3+m4yN stefanbondzulic@pm.me"
      ];
    };

    groups.bondzula = {
      gid = 1000;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];

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

  services.jellyfin = {
    enable = true;
    user = "bondzula";
    group = "bondzula";
  };

  system.stateVersion = "24.11";
}
