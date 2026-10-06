{ config, lib, pkgs, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.racuni;
in
{
  options.nixosModules.selfhosted.racuni = {
    enable = lib.mkEnableOption "racuni invoice application";
    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/bondzula/racuni:latest";
      description = "Private container image; latest follows tested main builds.";
    };
    autoUpdate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Let Podman's native auto-update service deploy new images.";
    };
    port = lib.mkOption { type = lib.types.port; default = 8080; };
    dataDir = lib.mkOption { type = lib.types.str; description = "Existing production directory mounted at /data."; };
    deploymentBackupDir = lib.mkOption { type = lib.types.str; description = "Pre-start snapshots, outside the app's backup retention."; };
    secretsFile = lib.mkOption { type = lib.types.str; description = "Root-owned environment file containing RACUNI_PASSWORD."; };
    registryAuthFile = lib.mkOption { type = lib.types.str; description = "Persistent root-owned Podman auth JSON for GHCR."; };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    systemd.tmpfiles.rules = [
      "d ${cfg.deploymentBackupDir} 0700 root root -"
      "d /root/.docker 0700 root root -"
      "L /root/.docker/config.json - root root - ${cfg.registryAuthFile}"
    ];
    virtualisation.quadlet.containers.racuni = {
      unitConfig.RequiresMountsFor = [ cfg.dataDir cfg.deploymentBackupDir ];
      containerConfig = {
        image = cfg.image;
        autoUpdate = if cfg.autoUpdate then "registry" else null;
        # Auto-update pulls changed images before restarting; cached images work at boot.
        pull = "missing";
        publishPorts = [ "${toString cfg.port}:8080" ];
        volumes = [ "${cfg.dataDir}:/data" ];
        user = "65532:65532";
        environments = { RACUNI_DATA = "/data"; RACUNI_ADDR = ":8080"; RACUNI_TZ = shared.timezone; };
        environmentFiles = [ cfg.secretsFile ];
        podmanArgs = [
          "--authfile=${cfg.registryAuthFile}"
          "--label=io.containers.autoupdate.authfile=${cfg.registryAuthFile}"
          "--label=important=true"
        ];
        notify = "healthy";
        # Execute directly: this scratch image has no /bin/sh.
        healthCmd = ''["/racuni", "healthcheck"]'';
        healthInterval = "30s";
        healthStartPeriod = "30s";
        healthRetries = 3;
        healthOnFailure = "kill";
      };
      serviceConfig = {
        UMask = "0077";
        # Native unit commands guard against an empty database and snapshot it
        # before startup migrations. %% escapes systemd's percent specifiers.
        ExecStartPre = [
          "${pkgs.coreutils}/bin/test -s ${cfg.dataDir}/racuni.db"
          "${pkgs.coreutils}/bin/test -s ${cfg.registryAuthFile}"
          "${pkgs.gnugrep}/bin/grep -Eq ^RACUNI_PASSWORD=.+$ ${cfg.secretsFile}"
          ''${pkgs.sqlite}/bin/sqlite3 -readonly "${cfg.dataDir}/racuni.db" "VACUUM INTO ('${cfg.deploymentBackupDir}/pre-start-' || strftime('%%Y%%m%%dT%%H%%M%%fZ','now') || '-' || lower(hex(randomblob(4))) || '.db');"''
        ];
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStartSec = "180s";
      };
    };
  };
}
