{ modulesPath, pkgs, lib, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../modules/nixos
  ];

  networking.hostName = "atreides";

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
      address = "192.168.1.20";
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

  nixosModules.selfhosted = {
    enable = true;

    immich = {
      enable = true;
      uploadLocation = "/mnt/immich";
      dbDataLocation = "/mnt/appdata/immich/db";
      modelCacheDir = "/mnt/appdata/immich/model-cache";
      secretsFile = "/mnt/appdata/immich/secrets.env";
      hwAccel.enable = true;
    };

    gitea = {
      enable = true;
      dataDir = "/mnt/gitea";
      configDir = "/mnt/appdata/gitea/data";
      dbDir = "/mnt/appdata/gitea/db";
      secretsFile = "/mnt/appdata/gitea/secrets.env";
    };

    paperless = {
      enable = true;
      dataDir = "/mnt/appdata/paperless/data";
      documentsDir = "/mnt/paperless";
      dbDir = "/mnt/appdata/paperless/db";
      redisDir = "/mnt/appdata/paperless/redis";
      secretsFile = "/mnt/appdata/paperless/secrets.env";
    };

    karakeep = {
      enable = true;
      dataDir = "/mnt/appdata/karakeep/data";
      meiliDir = "/mnt/appdata/karakeep/meilisearch";
      secretsFile = "/mnt/appdata/karakeep/secrets.env";
    };

    grocy = {
      enable = true;
      configDir = "/mnt/appdata/grocy";
    };
  };

  users = {
    users.bondzula = {
      initialHashedPassword = "$y$j9T$lTYSuKE.0BiJazE5fJ72B0$XMEo8mlRwfxuT6Q8bDielkRNGIFy.To2qsEYw7hbIm/";
      isNormalUser = true;
      description = "Stefan Bondzulic";
      extraGroups = [
        "podman"
        "render"
        "video"
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINF99lU/SLfVoC/Vua9Zbu58d57HfrZZNOZMuI/0xteL openpgp:0x2EED2F74"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiMjBO8faj7KwdeuXYlzBY/WYwMjjIb0L+B2iP5E5OE openpgp:0x25754616"
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

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
    discovery = true;
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "Fenring NAS Server";
        "netbios name" = "FENRING";
        "map to guest" = "Bad User";
        "dns proxy" = "no";
        "bind interfaces only" = "yes";
        interfaces = "lo eth0";
        "log file" = "/var/log/samba/%m.log";
        "max log size" = 1000;
        "server role" = "standalone server";
        "passdb backend" = "tdbsam";
        "load printers" = "no";
        "disable spoolss" = "yes";
        # Security posture:
        "server min protocol" = "SMB2";
        "client min protocol" = "SMB2";
        # For macOS clients
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:resource" = "stream";
      };

      Bondzula = {
        comment = "Bondzula Home";
        path = "/mnt/bondzula";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "bondzula";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force user" = "bondzula";
        "force group" = "bondzula";
      };

      Courses = {
        comment = "Video Courses";
        path = "/mnt/courses";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "bondzula";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force user" = "bondzula";
        "force group" = "bondzula";
      };

      Media = {
        comment = "Media";
        path = "/mnt/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "bondzula";
        "create mask" = "0640";
        "directory mask" = "0750";
        "force user" = "bondzula";
        "force group" = "bondzula";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/bondzula 0750 bondzula bondzula -"
  ];

  system.stateVersion = "24.11";
}

