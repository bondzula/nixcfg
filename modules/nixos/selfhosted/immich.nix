# Immich: server, machine-learning, valkey and the immich postgres, on a
# private network.
# No auto-update — update by bumping/pulling images (see host README).
{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.immich;
  inherit (config.virtualisation.quadlet) containers networks;
in
{
  options.nixosModules.selfhosted.immich = {
    enable = lib.mkEnableOption "Immich photo management";

    serverImage = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/immich-app/immich-server:release";
    };

    mlImage = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/immich-app/immich-machine-learning:release-openvino";
    };

    # Pinned by digest, same as the upstream compose file.
    redisImage = lib.mkOption {
      type = lib.types.str;
      default = "docker.io/valkey/valkey:8-bookworm@sha256:fea8b3e67b15729d4bb70589eb03367bab9ad1ee89c876f54327fc7c6e618571";
    };

    dbImage = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:41eacbe83eca995561fe43814fd4891e16e39632806253848efaf04d3c8a8b84";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 2283;
    };

    uploadLocation = lib.mkOption {
      type = lib.types.str;
      description = "Photo/video storage (compose-era UPLOAD_LOCATION), mounted as /data.";
    };

    dbDataLocation = lib.mkOption {
      type = lib.types.str;
      description = "Postgres data directory (compose-era DB_DATA_LOCATION).";
    };

    modelCacheDir = lib.mkOption {
      type = lib.types.str;
      description = "ML model cache; safe to wipe, re-downloads on demand.";
    };

    hwAccel = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Pass /dev/dri to the server (quicksync transcoding) and ML
          (openvino inference). The host must set hardware.graphics.enable;
          the units refuse to start if /dev/dri is missing.
        '';
      };
      device = lib.mkOption {
        type = lib.types.str;
        default = "/dev/dri";
      };
    };

    secretsFile = lib.mkOption {
      type = lib.types.str;
      description = ''
        Env file with DB_USERNAME/POSTGRES_USER, DB_PASSWORD/POSTGRES_PASSWORD,
        DB_DATABASE_NAME/POSTGRES_DB (both spellings, pairs must match).
      '';
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    assertions = [
      {
        assertion = cfg.hwAccel.enable -> config.hardware.graphics.enable;
        message = "selfhosted.immich.hwAccel needs hardware.graphics.enable = true on this host (Intel media/compute drivers).";
      }
    ];

    virtualisation.quadlet = {
      networks.immich = { };

      containers = {
        immich-server = {
          unitConfig = {
            After = [
              containers.immich-db.ref
              containers.immich-redis.ref
            ];
            Requires = [
              containers.immich-db.ref
              containers.immich-redis.ref
            ];
            AssertPathExists = lib.mkIf cfg.hwAccel.enable cfg.hwAccel.device;
          };
          containerConfig = {
            image = cfg.serverImage;
            devices = lib.optionals cfg.hwAccel.enable [ "${cfg.hwAccel.device}:${cfg.hwAccel.device}" ];
            publishPorts = [ "${toString cfg.port}:2283" ];
            volumes = [
              "${cfg.uploadLocation}:/data"
              "/etc/localtime:/etc/localtime:ro"
            ];
            environments = {
              TZ = shared.timezone;
              DB_HOSTNAME = "immich-db";
              REDIS_HOSTNAME = "immich-redis";
            };
            environmentFiles = [ cfg.secretsFile ];
            networks = [ networks.immich.ref ];
          };
          serviceConfig.Restart = "always";
        };

        # The server finds this via the default
        # http://immich-machine-learning:3003, so the name matters.
        immich-machine-learning = {
          unitConfig.AssertPathExists = lib.mkIf cfg.hwAccel.enable cfg.hwAccel.device;
          containerConfig = {
            image = cfg.mlImage;
            devices = lib.optionals cfg.hwAccel.enable [ "${cfg.hwAccel.device}:${cfg.hwAccel.device}" ];
            volumes = [ "${cfg.modelCacheDir}:/cache" ];
            networks = [ networks.immich.ref ];
          };
          serviceConfig.Restart = "always";
        };

        immich-redis = {
          containerConfig = {
            image = cfg.redisImage;
            healthCmd = "redis-cli ping || exit 1";
            notify = "healthy";
            networks = [ networks.immich.ref ];
          };
          serviceConfig.Restart = "always";
        };

        immich-db = {
          containerConfig = {
            image = cfg.dbImage;
            environments.POSTGRES_INITDB_ARGS = "--data-checksums";
            environmentFiles = [ cfg.secretsFile ];
            volumes = [ "${cfg.dbDataLocation}:/var/lib/postgresql/data" ];
            shmSize = "128m";
            healthCmd = "pg_isready -U \"$POSTGRES_USER\" -d \"$POSTGRES_DB\"";
            notify = "healthy";
            networks = [ networks.immich.ref ];
          };
          serviceConfig = {
            Restart = "always";
            # Major-version migrations can take a while.
            TimeoutStartSec = "600";
          };
        };
      };
    };
  };
}
