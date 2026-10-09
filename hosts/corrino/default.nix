{ modulesPath, pkgs, lib, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../modules/nixos
  ];

  networking.hostName = "corrino";

  nix.settings.sandbox = false;
  nix.settings.trusted-users = lib.mkForce [ "root" ];
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
      address = "192.168.1.10";
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

  nixosModules.selfhosted = {
    enable = true;

    caddy = {
      enable = true;
      image = "ghcr.io/caddybuilds/caddy-cloudflare@sha256:d679e8f61af683044999d689df6a41beda21c9841fddc70568aa3d051762998a";
      caddyfile = ./config/Caddyfile;
      dataDir = "/mnt/appdata/caddy/data";
      configDir = "/mnt/appdata/caddy/config";
      secretsFile = "/mnt/appdata/caddy/secrets.env";
    };

    homepage = {
      enable = true;
      allowedHosts = "homepage.local.bondzulic.com";
      dataDir = "/mnt/appdata/homepage";
      listenAddress = "10.88.0.1";
    };

    uptime-kuma = {
      enable = true;
      dataDir = "/mnt/appdata/uptime-kuma";
      listenAddress = "10.88.0.1";
    };
  };

  users = {
    users.bondzula = {
      initialHashedPassword = "$y$j9T$lTYSuKE.0BiJazE5fJ72B0$XMEo8mlRwfxuT6Q8bDielkRNGIFy.To2qsEYw7hbIm/";
      isNormalUser = true;
      description = "Stefan Bondzulic";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJYQ1fd/qI/5pM7aqSTn4lzO9/sc49pIkm9O6YK6z+K"
      ];
    };
    groups.bondzula.gid = 1000;
  };

  environment.systemPackages = with pkgs; [
    git neovim sqlite
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

  services.tailscale = {
    enable = true;
    port = 41641;
    useRoutingFeatures = "server";
    extraUpFlags = [ "--advertise-routes=192.168.1.0/24" ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 443 41641 ];
    trustedInterfaces = [ "tailscale0" ];
    checkReversePath = "loose";
    interfaces.podman0.allowedTCPPorts = [ 3000 3001 ];
  };

  # Back up mutable dashboard config, certificates and a consistent Kuma DB.
  systemd.services.corrino-backup = {
    description = "Back up Corino application state";
    requires = [ "uptime-kuma.service" ];
    after = [ "uptime-kuma.service" ];
    unitConfig.RequiresMountsFor = [ "/mnt/appdata" ];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
    };
    path = with pkgs; [ coreutils findutils gnutar gzip sqlite ];
    script = ''
      set -euo pipefail
      install -d -m 700 /var/backups/corrino
      staging=$(mktemp -d /var/backups/corrino/.staging.XXXXXX)
      trap 'rm -rf "$staging"' EXIT
      cp -a /mnt/appdata/caddy "$staging/caddy"
      cp -a /mnt/appdata/homepage "$staging/homepage"
      mkdir "$staging/uptime-kuma"
      tar -C /mnt/appdata/uptime-kuma \
        --exclude='./kuma.db' --exclude='./kuma.db-wal' --exclude='./kuma.db-shm' \
        -cf - . | tar -C "$staging/uptime-kuma" -xf -
      sqlite3 -cmd ".timeout 60000" /mnt/appdata/uptime-kuma/kuma.db ".backup '$staging/uptime-kuma/kuma.db'"
      test "$(sqlite3 "$staging/uptime-kuma/kuma.db" 'PRAGMA quick_check;')" = ok
      archive=/var/backups/corrino/daily-$(date -u +%Y%m%dT%H%M%SZ).tar.gz
      tar -C "$staging" -czf "$archive.partial" caddy homepage uptime-kuma
      mv "$archive.partial" "$archive"
      find /var/backups/corrino -maxdepth 1 -name 'daily-*.tar.gz' -mtime +7 -delete
    '';
  };
  systemd.timers.corrino-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:30:00";
      Persistent = true;
      RandomizedDelaySec = "10m";
    };
  };

  system.stateVersion = "24.11";
}

