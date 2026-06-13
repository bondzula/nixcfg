{ modulesPath, pkgs, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../modules/nixos
  ];

  networking.hostName = "richese";

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
      address = "192.168.1.41";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "192.168.1.1" ];

  time.timeZone = "Europe/Belgrade";
  i18n.defaultLocale = "en_US.UTF-8";

  nixosModules.selfhosted = {
    enable = true;

    prowlarr = {
      enable = true;
      configDir = "/mnt/appdata/prowlarr";
    };

    flaresolverr.enable = true;

    radarr = {
      enable = true;
      downloadDirs = [
        "/mnt/media/usenet"
        "/mnt/media/torrents"
      ];
      instances = {
        hd = {
          port = 7878;
          configDir = "/mnt/appdata/radarr-hd";
          mediaDirs = [ "/mnt/media/movies/1080p" ];
        };
        uhd = {
          port = 7879;
          configDir = "/mnt/appdata/radarr-uhd";
          mediaDirs = [ "/mnt/media/movies/4k" ];
        };
      };
    };

    sonarr = {
      enable = true;
      downloadDirs = [
        "/mnt/media/usenet"
        "/mnt/media/torrents"
      ];
      instances = {
        hd = {
          port = 8989;
          configDir = "/mnt/appdata/sonarr-hd";
          mediaDirs = [ "/mnt/media/tv/1080p" ];
        };
        uhd = {
          port = 8990;
          configDir = "/mnt/appdata/sonarr-uhd";
          mediaDirs = [ "/mnt/media/tv/4k" ];
        };
        anime = {
          port = 8991;
          configDir = "/mnt/appdata/sonarr-anime";
          mediaDirs = [ "/mnt/media/anime" ];
        };
      };
    };

    bazarr = {
      enable = true;
      instances = {
        hd = {
          port = 6767;
          configDir = "/mnt/appdata/bazarr-hd";
          mediaDirs = [
            "/mnt/media/movies/1080p"
            "/mnt/media/tv/1080p"
          ];
        };
        uhd = {
          port = 6768;
          configDir = "/mnt/appdata/bazarr-uhd";
          mediaDirs = [ "/mnt/media" ];
        };
        anime = {
          port = 6769;
          configDir = "/mnt/appdata/bazarr-anime";
          mediaDirs = [ "/mnt/media" ];
        };
      };
    };

    zilean = {
      enable = true;
      dataDir = "/mnt/appdata/zilean/data";
      tmpDir = "/mnt/appdata/zilean/tmp";
      dbDir = "/mnt/appdata/zilean/db";
      secretsFile = "/mnt/appdata/zilean/secrets.env";
    };

    notifiarr = {
      enable = true;
      configDir = "/mnt/appdata/notifiarr";
    };
  };

  users = {
    users.bondzula = {
      initialHashedPassword = "$y$j9T$lTYSuKE.0BiJazE5fJ72B0$XMEo8mlRwfxuT6Q8bDielkRNGIFy.To2qsEYw7hbIm/";
      isNormalUser = true;
      description = "Stefan Bondzulic";
      extraGroups = [ "wheel" "podman" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJYQ1fd/qI/5pM7aqSTn4lzO9/sc49pIkm9O6YK6z+K"
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

