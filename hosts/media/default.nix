{ modulesPath, pkgs, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix") # Substitute for hardware-config.nix when working with proxmox LXC
    ../../modules/nixos
  ];

  networking.hostName = "media";

  nix.settings.sandbox = false;
  nixpkgs.hostPlatform = "x86_64-linux";

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

  time.timeZone = "Europe/Belgrade";
  i18n.defaultLocale = "en_US.UTF-8";

  virtualisation.docker = {
    enable = true;
  };

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
        "docker"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINF99lU/SLfVoC/Vua9Zbu58d57HfrZZNOZMuI/0xteL openpgp:0x2EED2F74"
      ];
    };

    groups.bondzula.gid = 1000;
  };

  environment.systemPackages = with pkgs; [
    git neovim
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
