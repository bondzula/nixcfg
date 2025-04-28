# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
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
    # 550.xx production branch still supports Pascal-based MX130. :contentReference[oaicite:1]{index=1}
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    modesetting.enable = true; # Wayland / Plasma 6
    powerManagement.enable = true; # powers down dGPU when idle
    prime = {
      # “Offload” keeps battery usage low: Intel does 2-D; NV dGPU
      # wakes only when you run `nvidia-offload <app>`.
      offload.enable= true;
      intelBusId = "PCI:00:02:0";  # run `lspci | grep -E "VGA|3D"` to verify
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

  # CPU governor: raw speed on mains, grace on battery
  # services.auto-cpufreq.enable = true;
  # services.auto-cpufreq.settings = {
  #   battery = { governor = "powersave"; turbo = "off"; };
  #   ac      = { governor = "performance"; turbo = "on"; };
  # };

  networking.hostName = "jakku"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Belgrade";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  # services.xserver.enable = true;

  # programs.hyprland = {
  #   enable = true;
  #   xwayland.enable = true;
  # };

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.autoNumlock = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
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
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
