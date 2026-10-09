{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.homepage;

  configMounts = lib.optionals (cfg.configDir != null) (
    lib.mapAttrsToList (name: _: "${cfg.configDir}/${name}:/app/config/${name}:ro") (
      lib.filterAttrs (_: type: type == "regular") (builtins.readDir cfg.configDir)
    )
  );
in
{
  options.nixosModules.selfhosted.homepage = {
    enable = lib.mkEnableOption "Homepage dashboard";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address on which to publish the dashboard.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };

    allowedHosts = lib.mkOption {
      type = lib.types.str;
      description = "Value for HOMEPAGE_ALLOWED_HOSTS.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Writable host directory mounted as /app/config (logs, runtime state).";
    };

    configDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Directory of homepage YAML files kept in this repo, mounted
        read-only over dataDir. null = manage the config mutably in dataDir.
      '';
    };

    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet.containers.homepage = {
      unitConfig = {
        RequiresMountsFor = [ cfg.dataDir ];
      };
      containerConfig = {
        image = "ghcr.io/gethomepage/homepage:latest";
        healthCmd = "node -e \"require('http').get({host:'127.0.0.1',port:3000,headers:{Host:process.env.HOMEPAGE_ALLOWED_HOSTS.split(',')[0]}},r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))\"";
        healthInterval = "30s";
        healthTimeout = "10s";
        healthStartPeriod = "30s";
        healthRetries = 3;
        healthOnFailure = "kill";
        notify = "healthy";
        autoUpdate = if cfg.autoUpdate then "registry" else null;
        environments = {
          PUID = shared.uid;
          PGID = shared.gid;
          HOMEPAGE_ALLOWED_HOSTS = cfg.allowedHosts;
        };
        publishPorts = [ "${cfg.listenAddress}:${toString cfg.port}:3000" ];
        volumes = [
          "${cfg.dataDir}:/app/config"
        ]
        ++ configMounts;
      };
      serviceConfig = {
        Restart = "always";
        TimeoutStartSec = "120s";
      };
    };
  };
}
