# Jellystat + its postgres. If jellyfin is enabled on the same host, jellystat
# also joins the jellyfin network so it stays reachable by container name.
{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.jellystat;
  inherit (config.virtualisation.quadlet) containers networks;
in
{
  options.nixosModules.selfhosted.jellystat = {
    enable = lib.mkEnableOption "Jellystat statistics for Jellyfin";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory for jellystat backup data.";
    };

    dbDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory for the postgres data.";
    };

    secretsFile = lib.mkOption {
      type = lib.types.str;
      description = "Env file with POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, JWT_SECRET.";
    };

    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet = {
      networks.jellystat = { };

      containers = {
        jellystat = {
          unitConfig = {
            After = [ containers.jellystat-db.ref ];
            Requires = [ containers.jellystat-db.ref ];
          };
          containerConfig = {
            image = "docker.io/cyfershepard/jellystat:latest";
            autoUpdate = if cfg.autoUpdate then "registry" else null;
            user = shared.uid;
            group = shared.gid;
            environments = {
              POSTGRES_IP = "jellystat-db";
              POSTGRES_PORT = "5432";
            };
            environmentFiles = [ cfg.secretsFile ];
            publishPorts = [ "${toString cfg.port}:3000" ];
            volumes = [ "${cfg.dataDir}:/app/backend/backup-data" ];
            networks = [ networks.jellystat.ref ]
              ++ lib.optionals shared.jellyfin.enable [ networks.jellyfin.ref ];
          };
          serviceConfig.Restart = "always";
        };

        jellystat-db = {
          containerConfig = {
            image = "docker.io/library/postgres:15.2";
            user = shared.uid;
            group = shared.gid;
            environmentFiles = [ cfg.secretsFile ];
            volumes = [ "${cfg.dbDir}:/var/lib/postgresql/data" ];
            healthCmd = "pg_isready -U \"$POSTGRES_USER\"";
            notify = "healthy";
            networks = [ networks.jellystat.ref ];
          };
          serviceConfig = {
            Restart = "always";
            TimeoutStartSec = "300";
          };
        };
      };
    };
  };
}
