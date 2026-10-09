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

  # autovt@ aliases getty@; override the actual template so LXC's tty1
  # works without the /dev/tty0 virtual console device.
  systemd.services."getty@".unitConfig.ConditionPathExists = [
    ""
    "/dev/%I"
  ];

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

  security.sudo.extraConfig = ''
    Defaults:bondzula timestamp_type=global
    Defaults:bondzula timestamp_timeout=5
  '';

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
    autoUpdate.calendar = "*-*-* *:00/5:00";

    racuni = {
      enable = true;
      dataDir = "/srv/racuni/data";
      deploymentBackupDir = "/srv/racuni/deploy-backups";
      secretsFile = "/mnt/appdata/racuni/secrets.env";
      registryAuthFile = "/mnt/appdata/racuni/registry-auth.json";
    };

    immich = {
      enable = true;
      # The ZFS dataset contains the compose-era uploads directory.
      uploadLocation = "/mnt/immich/uploads";
      serverImage = "ghcr.io/immich-app/immich-server:v3.3.0";
      mlImage = "ghcr.io/immich-app/immich-machine-learning:v3.3.0-openvino";
      # Match the database and cache images shipped with Immich v3.3.0.
      redisImage = "docker.io/valkey/valkey:9@sha256:c123e3715db63d06d4ad6964884037aa0d5d4d703939b9929954112889708e1d";
      dbImage = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      dbDataLocation = "/mnt/appdata/immich/db";
      modelCacheDir = "/mnt/appdata/immich/model-cache";
      secretsFile = "/mnt/appdata/immich/secrets.env";
      hwAccel.enable = true;
    };

  };

  systemd.timers.podman-auto-update.timerConfig.RandomizedDelaySec = lib.mkForce 0;

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

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
    # Advertise shares on the LAN, ignoring ephemeral Podman interfaces.
    interface = "eth0";
    discovery = false;
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
        # Resource forks can exceed Linux's xattr size limit; use AppleDouble
        # sidecars while keeping small Finder metadata in streams_xattr.
        "fruit:resource" = "file";
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
