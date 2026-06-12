{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.jellyfin;
in
{
  options.nixosModules.selfhosted.jellyfin = {
    enable = lib.mkEnableOption "Jellyfin media server";

    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/jellyfin/jellyfin:latest";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8096;
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory mounted as /config.";
    };

    cacheDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory mounted as /cache.";
    };

    mediaDir = lib.mkOption {
      type = lib.types.str;
      description = "Media library, mounted at the same path inside the container.";
    };

    quickSync = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Pass an Intel render device for QSV transcoding. The host must set
          hardware.graphics.enable (drivers) and define the render group;
          the unit refuses to start if the device node is missing.
        '';
      };
      device = lib.mkOption {
        type = lib.types.str;
        default = "/dev/dri/renderD128";
      };
    };

    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    assertions = [
      {
        assertion = cfg.quickSync.enable -> config.hardware.graphics.enable;
        message = "selfhosted.jellyfin.quickSync needs hardware.graphics.enable = true on this host (Intel media drivers).";
      }
      {
        assertion = cfg.quickSync.enable -> (config.users.groups ? render && config.users.groups.render.gid != null);
        message = "selfhosted.jellyfin.quickSync needs users.groups.render.gid set (the GID is added to the container for ${cfg.quickSync.device}).";
      }
    ];

    virtualisation.quadlet.containers.jellyfin = {
      # Fail loudly at start instead of silently transcoding on CPU.
      unitConfig = lib.mkIf cfg.quickSync.enable {
        AssertPathExists = cfg.quickSync.device;
      };
      containerConfig = {
        image = cfg.image;
        autoUpdate = if cfg.autoUpdate then "registry" else null;
        user = shared.uid;
        group = shared.gid;
        addGroups = lib.optionals cfg.quickSync.enable [
          (toString config.users.groups.render.gid)
        ];
        devices = lib.optionals cfg.quickSync.enable [
          "${cfg.quickSync.device}:${cfg.quickSync.device}"
        ];
        noNewPrivileges = true;
        publishPorts = [ "${toString cfg.port}:8096" ];
        volumes = [
          "${cfg.configDir}:/config"
          "${cfg.cacheDir}:/cache"
          "${cfg.mediaDir}:${cfg.mediaDir}"
        ];
      };
      serviceConfig.Restart = "always";
    };
  };
}
