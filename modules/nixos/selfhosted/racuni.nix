{ config, lib, pkgs, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.racuni;
  preflight = pkgs.writeShellScript "racuni-preflight" ''
    set -euo pipefail
    db=${lib.escapeShellArg "${cfg.dataDir}/racuni.db"}
    if [ ! -s "$db" ]; then
      echo "racuni: refusing to create an empty production database at $db" >&2
      exit 1
    fi
    test -s ${lib.escapeShellArg cfg.registryAuthFile}
    test -f ${lib.escapeShellArg cfg.secretsFile}
    ${pkgs.gnugrep}/bin/grep -Eq '^RACUNI_PASSWORD=.+$' ${lib.escapeShellArg cfg.secretsFile}
    # Another ad-hoc container must not write to this database concurrently.
    for id in $(${pkgs.podman}/bin/podman ps -q); do
      name=$(${pkgs.podman}/bin/podman inspect "$id" | ${pkgs.jq}/bin/jq -r \
        --arg source ${lib.escapeShellArg cfg.dataDir} \
        '.[] | select(any(.Mounts[]?; .Source == $source and .RW)) | .Name')
      if [ -n "$name" ]; then
        echo "racuni: stop container $name before starting production" >&2
        exit 1
      fi
    done
    result=$(${pkgs.sqlite}/bin/sqlite3 -readonly "$db" 'PRAGMA quick_check;')
    if [ "$result" != ok ]; then
      echo "racuni: database integrity check failed: $result" >&2
      exit 1
    fi
    # SQLite's backup API includes committed WAL changes; raw .db copies do not.
    dir=${lib.escapeShellArg cfg.deploymentBackupDir}
    ${pkgs.coreutils}/bin/install -d -m 0700 "$dir"
    snapshot=$(${pkgs.coreutils}/bin/mktemp "$dir/pre-start-$(${pkgs.coreutils}/bin/date -u +%Y%m%dT%H%M%SZ)-XXXXXX.db")
    ${pkgs.sqlite}/bin/sqlite3 -readonly "$db" ".backup '$snapshot'"
    test "$(${pkgs.sqlite}/bin/sqlite3 -readonly "$snapshot" 'PRAGMA quick_check;')" = ok
    echo "racuni: saved pre-start database snapshot to $snapshot"
  '';
in
{
  options.nixosModules.selfhosted.racuni = {
    enable = lib.mkEnableOption "racuni invoice application";
    image = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Private GHCR image pinned by sha256 digest.";
    };
    port = lib.mkOption { type = lib.types.port; default = 8080; };
    dataDir = lib.mkOption { type = lib.types.str; description = "Existing production directory mounted at /data."; };
    deploymentBackupDir = lib.mkOption { type = lib.types.str; description = "Pre-start snapshots, outside the app's backup retention."; };
    secretsFile = lib.mkOption { type = lib.types.str; description = "Root-owned environment file containing RACUNI_PASSWORD."; };
    registryAuthFile = lib.mkOption { type = lib.types.str; description = "Persistent root-owned Podman auth JSON for GHCR."; };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    assertions = [{
      assertion = cfg.image != null && builtins.match "ghcr\\.io/bondzula/racuni@sha256:[0-9a-f]{64}" cfg.image != null;
      message = "racuni.image must pin ghcr.io/bondzula/racuni by sha256 digest.";
    }];
    virtualisation.quadlet.containers.racuni = {
      unitConfig.RequiresMountsFor = [ cfg.dataDir cfg.deploymentBackupDir ];
      containerConfig = {
        image = cfg.image;
        publishPorts = [ "${toString cfg.port}:8080" ];
        volumes = [ "${cfg.dataDir}:/data" ];
        user = "65532:65532";
        environments = { RACUNI_DATA = "/data"; RACUNI_ADDR = ":8080"; RACUNI_TZ = shared.timezone; };
        environmentFiles = [ cfg.secretsFile ];
        podmanArgs = [ "--authfile=${cfg.registryAuthFile}" "--label=important=true" ];
        notify = "healthy";
        healthCmd = "/racuni healthcheck";
        healthInterval = "30s";
        healthStartPeriod = "30s";
        healthRetries = 3;
        healthOnFailure = "kill";
      };
      serviceConfig = {
        ExecStartPre = [ "${preflight}" ];
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStartSec = "180s";
      };
    };
  };
}
