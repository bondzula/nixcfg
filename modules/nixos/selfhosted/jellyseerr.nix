{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.jellyseerr;
  inherit (config.virtualisation.quadlet) networks;
in
{
  options.nixosModules.selfhosted.jellyseerr = {
    enable = lib.mkEnableOption "Jellyseerr media requests";

    port = lib.mkOption {
      type = lib.types.port;
      default = 5055;
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory mounted as /app/config.";
    };

    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet.containers.jellyseerr = {
      containerConfig = {
        image = "docker.io/fallenbagel/jellyseerr:latest";
        autoUpdate = if cfg.autoUpdate then "registry" else null;
        user = shared.uid;
        group = shared.gid;
        environments.TZ = shared.timezone;
        publishPorts = [ "${toString cfg.port}:5055" ];
        volumes = [ "${cfg.configDir}:/app/config" ];
        networks = lib.optionals shared.jellyfin.enable [ networks.jellyfin.ref ];
      };
      serviceConfig.Restart = "always";
    };
  };
}
