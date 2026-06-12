{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.rdtclient;
in
{
  options.nixosModules.selfhosted.rdtclient = {
    enable = lib.mkEnableOption "Real-Debrid Torrent Client";

    port = lib.mkOption {
      type = lib.types.port;
      default = 6500;
    };

    dbDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory mounted as /data/db.";
    };

    downloadsDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory mounted as /data/downloads.";
    };

    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet.containers.rdtclient = {
      containerConfig = {
        image = "docker.io/rogerfar/rdtclient:latest";
        autoUpdate = if cfg.autoUpdate then "registry" else null;
        environments = {
          PUID = shared.uid;
          PGID = shared.gid;
          TZ = shared.timezone;
        };
        publishPorts = [ "${toString cfg.port}:6500" ];
        volumes = [
          "${cfg.dbDir}:/data/db"
          "${cfg.downloadsDir}:/data/downloads"
        ];
      };
      serviceConfig.Restart = "always";
    };
  };
}
