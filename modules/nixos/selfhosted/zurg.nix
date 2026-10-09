{ config, lib, pkgs, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.zurg;
  # JSON is valid YAML. Keep credentials out of the Nix store and serialize
  # them at startup rather than interpolating unescaped values into YAML.
  publicConfig = (pkgs.formats.json { }).generate "zurg-config.json" {
    zurg = "v1";
    host = "0.0.0.0";
    port = 9999;
    disable_stream_proxy = true;
    serve_strm_files = false;
    save_strm_files = false;
    rclone_enabled = false;
    auto_analyze_new_torrents = false;
    # An index service should not alter the AllDebrid account's torrents.
    enable_repair = false;
    delete_error_torrents = false;
    check_for_changes_every_secs = 60;
    directories.all.filters = [ { regex = "/.*/"; } ];
  };
  prepareConfig = pkgs.writeScript "zurg-prepare-config" ''
    #!${pkgs.python3}/bin/python3
    import json
    import os
    from pathlib import Path

    with open("${publicConfig}") as source:
        settings = json.load(source)
    token = os.environ.get("ZURG_AD_TOKEN", "")
    if not token.strip():
        raise SystemExit("Missing required environment variable: ZURG_AD_TOKEN")
    settings["providers"] = [{"type": "alldebrid", "token": token, "add_torrents": False}]
    for key, variable in (
        ("username", "ZURG_USERNAME"),
        ("password", "ZURG_PASSWORD"),
    ):
        value = os.environ.get(variable, "")
        if not value.strip():
            raise SystemExit(f"Missing required environment variable: {variable}")
        settings[key] = value
    os.umask(0o077)
    target = Path("/run/zurg/config.yml")
    target.write_text(json.dumps(settings) + "\n")
    target.chmod(0o600)
  '';
in
{
  options.nixosModules.selfhosted.zurg = {
    enable = lib.mkEnableOption "Zurg AllDebrid WebDAV index with direct-download redirects";

    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/debridmediamanager/zurg:latest";
      description = "Sponsor-only nightly image with AllDebrid support; may be overridden with a specific nightly tag.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9999;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Persistent index/cache directory mounted at /app/data.";
    };

    secretsFile = lib.mkOption {
      type = lib.types.str;
      description = "Private systemd environment file with ZURG_AD_TOKEN, ZURG_USERNAME and ZURG_PASSWORD. May be owned by the host user (mode 0600).";
    };

    registryAuthFile = lib.mkOption {
      type = lib.types.str;
      description = "Persistent private Podman auth JSON for the sponsor-only GHCR image. May be owned by the host user (mode 0600).";
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    systemd.tmpfiles.rules = [ "d ${cfg.dataDir} 0700 ${shared.uid} ${shared.gid} -" ];

    virtualisation.quadlet.containers.zurg = {
      unitConfig.RequiresMountsFor = [ cfg.dataDir cfg.secretsFile cfg.registryAuthFile ];
      containerConfig = {
        image = cfg.image;
        pull = "missing";
        podmanArgs = [ "--authfile=${cfg.registryAuthFile}" ];
        publishPorts = [ "${toString cfg.port}:9999" ];
        volumes = [
          "/run/zurg/config.yml:/app/config.yml:ro"
          "${cfg.dataDir}:/app/data"
        ];
        environments.TZ = shared.timezone;
      };
      serviceConfig = {
        EnvironmentFile = cfg.secretsFile;
        RuntimeDirectory = "zurg";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/test -s ${cfg.registryAuthFile}"
          "${prepareConfig}"
        ];
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
