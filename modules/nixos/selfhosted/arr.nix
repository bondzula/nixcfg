# The *arr media automation family: radarr, sonarr, bazarr (multi-instance),
# prowlarr, flaresolverr, zilean and notifiarr. Whenever any of them is
# enabled they share the "arr" podman network, so the URLs stored inside the
# apps (prowlarr -> flaresolverr, prowlarr -> radarr/sonarr, ...) resolve by
# container name.
#
# Instances produce a container "<app>-<instance>":
#
#   nixosModules.selfhosted.radarr = {
#     enable = true;
#     downloadDirs = [ "/mnt/media/torrents" ];
#     instances.hd = {
#       port = 7878;
#       configDir = "/mnt/appdata/radarr-hd";
#       mediaDirs = [ "/mnt/media/movies/1080p" ];
#     };
#   };
{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared;
  inherit (config.virtualisation.quadlet) containers networks;

  anyArrEnabled =
    cfg.radarr.enable
    || cfg.sonarr.enable
    || cfg.bazarr.enable
    || cfg.prowlarr.enable
    || cfg.flaresolverr.enable
    || cfg.zilean.enable
    || cfg.notifiarr.enable;

  instanceType = lib.types.submodule {
    options = {
      port = lib.mkOption {
        type = lib.types.port;
        description = "Host port for the web UI.";
      };
      configDir = lib.mkOption {
        type = lib.types.str;
        description = "Host directory mounted as /config.";
      };
      mediaDirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Media directories, mounted at the same path inside the container.";
      };
    };
  };

  mkInstancedApp = app: {
    enable = lib.mkEnableOption "${app} (multi-instance)";
    instances = lib.mkOption {
      type = lib.types.attrsOf instanceType;
      default = { };
      description = "${app} instances, keyed by suffix (hd, uhd, anime, ...).";
    };
  };

  # linuxserver.io container on the arr network.
  mkLsio = configDir: app: ports: media: {
    containerConfig = {
      image = "lscr.io/linuxserver/${app}:latest";
      autoUpdate = "registry";
      noNewPrivileges = true;
      environments = {
        PUID = shared.uid;
        PGID = shared.gid;
        TZ = shared.timezone;
      };
      publishPorts = ports;
      volumes = [ "${configDir}:/config" ] ++ media;
      networks = [ networks.arr.ref ];
    };
    serviceConfig.Restart = "always";
  };

  samePath = dirs: map (d: "${d}:${d}") dirs;

  mkInstances =
    app: internalPort: extraDirs: appCfg:
    lib.mkIf appCfg.enable (
      lib.mapAttrs' (
        suffix: instance:
        lib.nameValuePair "${app}-${suffix}" (
          mkLsio instance.configDir app [ "${toString instance.port}:${toString internalPort}" ] (
            samePath (extraDirs ++ instance.mediaDirs)
          )
        )
      ) appCfg.instances
    );
in
{
  options.nixosModules.selfhosted = {
    radarr = mkInstancedApp "radarr" // {
      downloadDirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Mounted into every instance at the same path.";
      };
    };

    sonarr = mkInstancedApp "sonarr" // {
      downloadDirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Mounted into every instance at the same path.";
      };
    };

    bazarr = mkInstancedApp "bazarr";

    prowlarr = {
      enable = lib.mkEnableOption "Prowlarr indexer manager";
      port = lib.mkOption {
        type = lib.types.port;
        default = 9696;
      };
      configDir = lib.mkOption {
        type = lib.types.str;
        description = "Host directory mounted as /config.";
      };
    };

    flaresolverr.enable = lib.mkEnableOption "FlareSolverr (no published port; reached at http://flaresolverr:8191)";

    zilean = {
      enable = lib.mkEnableOption "Zilean DMM indexer (+ its postgres)";
      port = lib.mkOption {
        type = lib.types.port;
        default = 8181;
      };
      dataDir = lib.mkOption {
        type = lib.types.str;
        description = "Host directory mounted as /app/data.";
      };
      tmpDir = lib.mkOption {
        type = lib.types.str;
        description = "Host directory mounted as /tmp.";
      };
      dbDir = lib.mkOption {
        type = lib.types.str;
        description = "Host directory for the postgres data.";
      };
      secretsFile = lib.mkOption {
        type = lib.types.str;
        description = "Env file with POSTGRES_PASSWORD (shared with zilean-db).";
      };
    };

    notifiarr = {
      enable = lib.mkEnableOption "Notifiarr client";
      port = lib.mkOption {
        type = lib.types.port;
        default = 5454;
      };
      configDir = lib.mkOption {
        type = lib.types.str;
        description = "Host directory mounted as /config.";
      };
    };
  };

  config = lib.mkIf (shared.enable && anyArrEnabled) {
    virtualisation.quadlet = {
      networks.arr = { };

      containers = lib.mkMerge [
        (mkInstances "radarr" 7878 cfg.radarr.downloadDirs cfg.radarr)
        (mkInstances "sonarr" 8989 cfg.sonarr.downloadDirs cfg.sonarr)
        (mkInstances "bazarr" 6767 [ ] cfg.bazarr)

        (lib.mkIf cfg.prowlarr.enable {
          prowlarr =
            mkLsio cfg.prowlarr.configDir "prowlarr"
              [ "${toString cfg.prowlarr.port}:9696" ]
              [ ];
        })

        (lib.mkIf cfg.flaresolverr.enable {
          flaresolverr = {
            containerConfig = {
              image = "ghcr.io/flaresolverr/flaresolverr:latest";
              autoUpdate = "registry";
              noNewPrivileges = true;
              environments.LOG_LEVEL = "info";
              networks = [ networks.arr.ref ];
            };
            serviceConfig.Restart = "always";
          };
        })

        (lib.mkIf cfg.zilean.enable {
          zilean = {
            unitConfig = {
              After = [ containers.zilean-db.ref ];
              Requires = [ containers.zilean-db.ref ];
            };
            containerConfig = {
              image = "docker.io/ipromknight/zilean:latest";
              autoUpdate = "registry";
              user = shared.uid;
              group = shared.gid;
              podmanArgs = [ "--tty" ];
              environmentFiles = [ cfg.zilean.secretsFile ];
              publishPorts = [ "${toString cfg.zilean.port}:8181" ];
              volumes = [
                "${cfg.zilean.dataDir}:/app/data"
                "${cfg.zilean.tmpDir}:/tmp"
              ];
              healthCmd = "curl --connect-timeout 10 --silent --show-error --fail http://localhost:8181/healthchecks/ping";
              healthInterval = "30s";
              healthTimeout = "60s";
              healthRetries = 10;
              networks = [ networks.arr.ref ];
            };
            serviceConfig.Restart = "always";
          };

          zilean-db = {
            containerConfig = {
              image = "docker.io/library/postgres:17.2-alpine";
              autoUpdate = "registry";
              user = shared.uid;
              group = shared.gid;
              shmSize = "2g";
              environments = {
                PGDATA = "/var/lib/postgresql/data/pgdata";
                POSTGRES_USER = "postgres";
                POSTGRES_DB = "zilean";
              };
              environmentFiles = [ cfg.zilean.secretsFile ];
              volumes = [ "${cfg.zilean.dbDir}:/var/lib/postgresql/data/pgdata" ];
              healthCmd = "pg_isready -U postgres";
              notify = "healthy";
              networks = [ networks.arr.ref ];
            };
            serviceConfig = {
              Restart = "always";
              TimeoutStartSec = "300";
            };
          };
        })

        (lib.mkIf cfg.notifiarr.enable {
          notifiarr = {
            containerConfig = {
              image = "docker.io/golift/notifiarr:latest";
              autoUpdate = "registry";
              hostname = "notifiarr";
              noNewPrivileges = true;
              publishPorts = [ "${toString cfg.notifiarr.port}:5454" ];
              volumes = [
                "${cfg.notifiarr.configDir}:/config"
                "/var/run/utmp:/var/run/utmp"
                "/etc/machine-id:/etc/machine-id"
              ];
              networks = [ networks.arr.ref ];
            };
            serviceConfig.Restart = "always";
          };
        })
      ];
    };
  };
}
