{ modulesPath, pkgs, lib, inputs, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix") # Substitute for hardware-config.nix when working with proxmox LXC
    ../../modules/nixos
    inputs.quadlet-nix.nixosModules.quadlet
    ./media.nix
  ];

  networking.hostName = "vernius";

  nix.settings.sandbox = false;
  nixpkgs.hostPlatform = "x86_64-linux";

  proxmoxLXC = {
    # NixOS owns the IP config below; Proxmox net0 only provides the
    # bridge/MAC (set its IPv4 mode to "Static" with no address).
    manageNetwork = true;
    privileged = false;
  };

  networking.useDHCP = false;
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "192.168.1.30";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "192.168.1.1" ];

  time.timeZone = "Europe/Belgrade";
  i18n.defaultLocale = "en_US.UTF-8";

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # iHD: mandatory for Arc
      intel-compute-runtime # OpenCL: HDR tone-mapping & subtitles
      vpl-gpu-rt # QSV on 11th gen or newer
      intel-ocl # OpenCL support
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    LIBVA_DRIVERS_PATH = "${pkgs.intel-media-driver}/lib/dri";
  };

  # Containers run as podman quadlets, see media.nix.
  # dockerCompat in this module keeps the `docker` CLI working as an alias.
  nixosModules.podman.enable = true;

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
        "podman"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJYQ1fd/qI/5pM7aqSTn4lzO9/sc49pIkm9O6YK6z+K"
      ];
    };

    groups.video.gid = lib.mkForce 44;
    groups.render.gid = lib.mkForce 104;
    groups.bondzula.gid = 1000;
  };

  environment.systemPackages = with pkgs; [
    git neovim libva-utils
  ];

  services.openssh = {
    enable = true;
    allowSFTP = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  networking.firewall.enable = false;

  system.stateVersion = "24.11";
}
