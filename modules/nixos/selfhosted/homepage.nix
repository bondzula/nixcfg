# Homepage dashboard. Talks to the docker-compatible podman socket for its
# container widgets, so this module also enables the socket.
#
# When configDir is set (a directory in this repo, e.g. ./config/homepage),
# every file in it is mounted read-only over the writable dataDir — the
# dashboard config lives in git, while logs and runtime state stay on the
# host. Editing a file + rebuild restarts the container.
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
    virtualisation.podman.dockerSocket.enable = true;

    virtualisation.quadlet.containers.homepage = {
      unitConfig = {
        After = [ "podman.socket" ];
        Requires = [ "podman.socket" ];
      };
      containerConfig = {
        image = "ghcr.io/gethomepage/homepage:latest";
        autoUpdate = if cfg.autoUpdate then "registry" else null;
        environments = {
          PUID = shared.uid;
          PGID = shared.gid;
          HOMEPAGE_ALLOWED_HOSTS = cfg.allowedHosts;
        };
        publishPorts = [ "${toString cfg.port}:3000" ];
        volumes = [
          "${cfg.dataDir}:/app/config"
          "/run/podman/podman.sock:/var/run/docker.sock:ro"
        ]
        ++ configMounts;
      };
      serviceConfig.Restart = "always";
    };
  };
}
