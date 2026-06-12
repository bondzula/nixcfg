{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.sabnzbd;
in
{
  options.nixosModules.selfhosted.sabnzbd = {
    enable = lib.mkEnableOption "SABnzbd usenet downloader";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory mounted as /config.";
    };

    usenetDir = lib.mkOption {
      type = lib.types.str;
      description = "Usenet downloads, mounted at the same path inside the container.";
    };

    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet.containers.sabnzbd = {
      containerConfig = {
        image = "lscr.io/linuxserver/sabnzbd:latest";
        autoUpdate = if cfg.autoUpdate then "registry" else null;
        environments = {
          PUID = shared.uid;
          PGID = shared.gid;
          TZ = shared.timezone;
        };
        publishPorts = [ "${toString cfg.port}:8080" ];
        volumes = [
          "${cfg.configDir}:/config"
          "${cfg.usenetDir}:${cfg.usenetDir}"
        ];
      };
      serviceConfig.Restart = "always";
    };
  };
}
