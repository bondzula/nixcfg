{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.grocy;
in
{
  options.nixosModules.selfhosted.grocy = {
    enable = lib.mkEnableOption "Grocy household management";

    port = lib.mkOption {
      type = lib.types.port;
      default = 9283;
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory mounted as /config.";
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet.containers.grocy = {
      containerConfig = {
        image = "lscr.io/linuxserver/grocy:latest";
        environments = {
          PUID = shared.uid;
          PGID = shared.gid;
          TZ = shared.timezone;
        };
        publishPorts = [ "${toString cfg.port}:80" ];
        volumes = [ "${cfg.configDir}:/config" ];
      };
      serviceConfig.Restart = "always";
    };
  };
}
