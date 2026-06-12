{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.uptime-kuma;
in
{
  options.nixosModules.selfhosted.uptime-kuma = {
    enable = lib.mkEnableOption "Uptime Kuma monitoring";

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
      containerConfig = {
        image = "docker.io/louislam/uptime-kuma:1";
        publishPorts = [ "${toString cfg.port}:3001" ];
        volumes = [ "${cfg.dataDir}:/app/data" ];
      };
      serviceConfig.Restart = "always";
    };
  };
}
