{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.caddy;
in
{
  options.nixosModules.selfhosted.caddy = {
    enable = lib.mkEnableOption "Caddy reverse proxy";

    # Prebuilt caddy + cloudflare DNS plugin (replaces the old xcaddy build).
    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/caddybuilds/caddy-cloudflare:latest";
    };

    caddyfile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to the Caddyfile (kept in the host directory, e.g.
        ./config/Caddyfile). Mounted read-only from the nix store; editing
        it + rebuild restarts the container.
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Certificates and ACME state, mounted as /data.";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      description = "Caddy runtime config storage, mounted as /config.";
    };

    secretsFile = lib.mkOption {
      type = lib.types.str;
      description = "Env file with CLOUDFLARE_EMAIL, CLOUDFLARE_API_TOKEN.";
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet.containers.caddy = {
      containerConfig = {
        image = cfg.image;
        publishPorts = [
          "80:80"
          "443:443"
        ];
        volumes = [
          "${cfg.caddyfile}:/etc/caddy/Caddyfile:ro"
          "${cfg.dataDir}:/data"
          "${cfg.configDir}:/config"
        ];
        environments.ACME_AGREE = "true";
        environmentFiles = [ cfg.secretsFile ];
      };
      serviceConfig.Restart = "always";
    };
  };
}
