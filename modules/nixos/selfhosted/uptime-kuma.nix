{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.uptime-kuma;
in
{
  options.nixosModules.selfhosted.uptime-kuma = {
    enable = lib.mkEnableOption "Uptime Kuma monitoring";

    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/louislam/uptime-kuma:2.5.5";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3001;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory mounted as /app/data.";
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet.containers.uptime-kuma = {
      unitConfig.RequiresMountsFor = [ cfg.dataDir ];
      containerConfig = {
        image = cfg.image;
        healthCmd = "node -e \"require('http').get('http://127.0.0.1:3001/',r=>process.exit(r.statusCode<400?0:1)).on('error',()=>process.exit(1))\"";
        healthInterval = "30s";
        healthTimeout = "10s";
        # A v1 migration may take hours. Report health without restarting it.
        healthStartPeriod = "24h";
        healthRetries = 3;
        publishPorts = [ "${cfg.listenAddress}:${toString cfg.port}:3001" ];
        volumes = [ "${cfg.dataDir}:/app/data" ];
      };
      serviceConfig.Restart = "always";
    };
  };
}
