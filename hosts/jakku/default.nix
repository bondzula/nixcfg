{ config, inputs, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
    ./home.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Machine Name
  networking.hostName = "jakku";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Belgrade";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.autoNumlock = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # User setup
  users.users.bondzula = {
    initialHashedPassword = "$y$j9T$lTYSuKE.0BiJazE5fJ72B0$XMEo8mlRwfxuT6Q8bDielkRNGIFy.To2qsEYw7hbIm/";
    isNormalUser = true;
    description = "Stefan Bondzulic";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1UcE51oQhUbXEdGHvlJMSmKJQCVsP7xt5Tmj3+m4yN stefanbondzulic@pm.me"
    ];
    packages = [
      inputs.home-manager.packages.${pkgs.system}.default
    ];
  };

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ]; # brlaser supports the entire DCP-1510 series
  };

  # Scanning (Brother’s brscan4 backend)
  hardware.sane = {
    enable = true;            # turn on SANE globally
    brscan4.enable = true;    # DCP-1510 uses the brscan4 backend
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [];

  # List services that you want to enable:
  nixosModules = {
    zsh.enable = true;
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

  # Performance Improvments
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams   = [ "mitigations=off" "nowatchdog" "audit=0" "intel_pstate=active" ];

  # Ensure nouveau never grabs the card before the proprietary driver
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Micro-code still fixes outright *functional* bugs, so keep it.
  hardware.cpu.intel.updateMicrocode = true;

  # Hybrid-GPU (Intel UHD 620 + GeForce MX130)
  services.xserver.videoDrivers = [ "nvidia" "modesetting" ];

  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    modesetting.enable = true;
    powerManagement.enable = true;
    prime = {
      # “Offload” keeps battery usage low: Intel does 2-D; NV dGPU
      # wakes only when you run `nvidia-offload <app>`.
      offload.enable= true;
      # run `lspci | grep -E "VGA|3D"` to verify
      intelBusId = "PCI:00:02:0";
      nvidiaBusId = "PCI:01:00:0";
    };
  };

  # OpenGL / Video acceleration on the iGPU
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      libvdpau-va-gl
    ];
  };

  system.stateVersion = "24.11";
}
