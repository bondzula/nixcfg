{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.gitea;
  inherit (config.virtualisation.quadlet) containers networks;
in
{
  options.nixosModules.selfhosted.gitea = {
    enable = lib.mkEnableOption "Gitea git forge";

    # No auto-update; bump and rebuild.
    image = lib.mkOption {
      type = lib.types.str;
      default = "docker.gitea.com/gitea:1.24.6-rootless";
    };

    httpPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };

    sshPort = lib.mkOption {
      type = lib.types.port;
      default = 2222;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Repositories and application data, mounted as /var/lib/gitea.";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      description = "Gitea configuration, mounted as /etc/gitea.";
    };

    dbDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory for the postgres data.";
    };

    secretsFile = lib.mkOption {
      type = lib.types.str;
      description = ''
        Env file with GITEA__database__NAME/USER/PASSWD and matching
        POSTGRES_DB/USER/PASSWORD (both spellings, pairs must match).
      '';
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet = {
      networks.gitea = { };

      containers = {
        gitea = {
          unitConfig = {
            After = [ containers.gitea-db.ref ];
            Requires = [ containers.gitea-db.ref ];
          };
          containerConfig = {
            image = cfg.image;
            environments = {
              GITEA__database__DB_TYPE = "postgres";
              GITEA__database__HOST = "gitea-db:5432";
            };
            environmentFiles = [ cfg.secretsFile ];
            publishPorts = [
              "${toString cfg.httpPort}:3000"
              "${toString cfg.sshPort}:2222"
            ];
            volumes = [
              "${cfg.dataDir}:/var/lib/gitea"
              "${cfg.configDir}:/etc/gitea"
              "/etc/localtime:/etc/localtime:ro"
            ];
            networks = [ networks.gitea.ref ];
          };
          serviceConfig.Restart = "always";
        };

        gitea-db = {
          containerConfig = {
            image = "docker.io/library/postgres:14";
            environmentFiles = [ cfg.secretsFile ];
            volumes = [ "${cfg.dbDir}:/var/lib/postgresql/data" ];
            healthCmd = "pg_isready -U \"$POSTGRES_USER\"";
            notify = "healthy";
            networks = [ networks.gitea.ref ];
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
