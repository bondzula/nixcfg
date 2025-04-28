# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, outputs, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the low-latency Zen build and switch **all** speculative-execution
  # mitigations off.  Add a couple of other flags that shave µs off context
  # switches on older Intel parts.
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams   = [
    "mitigations=off"       # disable Spectre/Meltdown/etc. :contentReference[oaicite:0]{index=0}
    "nowatchdog"            # drop kernel soft-watchdog
    "audit=0"               # disable audit subsystem
    "intel_pstate=active"   # use HW P-states with performance governor
  ];

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

  # Ensure nouveau never grabs the card before the proprietary driver
  boot.blacklistedKernelModules = [ "nouveau" ];

  # OpenGL / Video acceleration on the iGPU
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      libvdpau-va-gl
    ];
  };

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

  # Home Manager setup
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs outputs; };
  };

  # Load the user config for the host
  home-manager.users.bondzula =
    import ../../../home/hosts/jakku/bondzula.nix;

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
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  osModules.zsh.enable = true;

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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
