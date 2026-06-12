{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.speedtest-tracker;
in
{
  options.nixosModules.selfhosted.speedtest-tracker = {
    enable = lib.mkEnableOption "Speedtest Tracker";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory mounted as /config.";
    };

    secretsFile = lib.mkOption {
      type = lib.types.str;
      description = "Env file with APP_KEY.";
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet.containers.speedtest-tracker = {
      containerConfig = {
        image = "lscr.io/linuxserver/speedtest-tracker:latest";
        environments = {
          PUID = shared.uid;
          PGID = shared.gid;
          DB_CONNECTION = "sqlite";
        };
        environmentFiles = [ cfg.secretsFile ];
        publishPorts = [ "${toString cfg.port}:80" ];
        volumes = [ "${cfg.configDir}:/config" ];
      };
      serviceConfig.Restart = "always";
    };
  };
}
