{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.paperless;
  inherit (config.virtualisation.quadlet) containers networks;
in
{
  options.nixosModules.selfhosted.paperless = {
    enable = lib.mkEnableOption "Paperless-ngx document management";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Application state, mounted as /usr/src/paperless/data.";
    };

    documentsDir = lib.mkOption {
      type = lib.types.str;
      description = "Holds media/, export/ and consume/.";
    };

    dbDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory for the postgres data.";
    };

    redisDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory for the redis broker data.";
    };

    secretsFile = lib.mkOption {
      type = lib.types.str;
      description = ''
        Env file with the compose-era settings (PAPERLESS_URL,
        PAPERLESS_SECRET_KEY, OCR settings, PAPERLESS_DB*) plus matching
        POSTGRES_DB/USER/PASSWORD. PAPERLESS_DBHOST is overridden here.
      '';
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet = {
      networks.paperless = { };

      containers = {
        paperless = {
          unitConfig = {
            After = [
              containers.paperless-db.ref
              containers.paperless-broker.ref
            ];
            Requires = [
              containers.paperless-db.ref
              containers.paperless-broker.ref
            ];
          };
          containerConfig = {
            image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
            # Inline values override the secrets file.
            environments = {
              PAPERLESS_REDIS = "redis://paperless-broker:6379";
              PAPERLESS_DBHOST = "paperless-db";
            };
            environmentFiles = [ cfg.secretsFile ];
            publishPorts = [ "${toString cfg.port}:8000" ];
            volumes = [
              "${cfg.dataDir}:/usr/src/paperless/data"
              "${cfg.documentsDir}/media:/usr/src/paperless/media"
              "${cfg.documentsDir}/export:/usr/src/paperless/export"
              "${cfg.documentsDir}/consume:/usr/src/paperless/consume"
            ];
            networks = [ networks.paperless.ref ];
          };
          serviceConfig.Restart = "always";
        };

        paperless-db = {
          containerConfig = {
            image = "docker.io/library/postgres:17";
            user = shared.uid;
            group = shared.gid;
            environmentFiles = [ cfg.secretsFile ];
            volumes = [ "${cfg.dbDir}:/var/lib/postgresql/data" ];
            healthCmd = "pg_isready -U \"$POSTGRES_USER\"";
            notify = "healthy";
            networks = [ networks.paperless.ref ];
          };
          serviceConfig = {
            Restart = "always";
            TimeoutStartSec = "300";
          };
        };

        paperless-broker = {
          containerConfig = {
            image = "docker.io/library/redis:8";
            user = shared.uid;
            group = shared.gid;
            volumes = [ "${cfg.redisDir}:/data" ];
            healthCmd = "redis-cli ping || exit 1";
            notify = "healthy";
            networks = [ networks.paperless.ref ];
          };
          serviceConfig.Restart = "always";
        };
      };
    };
  };
}
