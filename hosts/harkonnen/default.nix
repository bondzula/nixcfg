{ modulesPath, pkgs, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../modules/nixos
  ];

  networking.hostName = "harkonnen";

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
      address = "192.168.1.40";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "192.168.1.1" ];

  time.timeZone = "Europe/Belgrade";
  i18n.defaultLocale = "en_US.UTF-8";

  # gluetun + qbittorrent are intentionally not migrated yet (not live).
  nixosModules.selfhosted = {
    enable = true;

    rdtclient = {
      enable = true;
      dbDir = "/mnt/appdata";
      downloadsDir = "/mnt/media/torrents";
    };

    sabnzbd = {
      enable = true;
      configDir = "/mnt/appdata/sabnzbd";
      usenetDir = "/mnt/media/usenet";
    };
  };

  users = {
    users.bondzula = {
      initialHashedPassword = "$y$j9T$lTYSuKE.0BiJazE5fJ72B0$XMEo8mlRwfxuT6Q8bDielkRNGIFy.To2qsEYw7hbIm/";
      isNormalUser = true;
      description = "Stefan Bondzulic";
      extraGroups = [ "wheel" "podman" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINF99lU/SLfVoC/Vua9Zbu58d57HfrZZNOZMuI/0xteL openpgp:0x2EED2F74"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiMjBO8faj7KwdeuXYlzBY/WYwMjjIb0L+B2iP5E5OE openpgp:0x25754616"
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

