{ config, lib, ... }:

let
  shared = config.nixosModules.selfhosted;
  cfg = shared.karakeep;
  inherit (config.virtualisation.quadlet) networks;
in
{
  options.nixosModules.selfhosted.karakeep = {
    enable = lib.mkEnableOption "Karakeep bookmark manager";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3050;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Host directory mounted as /data.";
    };

    meiliDir = lib.mkOption {
      type = lib.types.str;
      description = "Meilisearch index data (rebuildable via admin reindex).";
    };

    secretsFile = lib.mkOption {
      type = lib.types.str;
      description = "Env file with NEXTAUTH_SECRET, NEXTAUTH_URL, MEILI_MASTER_KEY.";
    };
  };

  config = lib.mkIf (shared.enable && cfg.enable) {
    virtualisation.quadlet = {
      networks.karakeep = { };

      containers = {
        karakeep = {
          containerConfig = {
            image = "ghcr.io/karakeep-app/karakeep:release";
            environments = {
              MEILI_ADDR = "http://karakeep-meilisearch:7700";
              BROWSER_WEB_URL = "http://karakeep-chrome:9222";
              DATA_DIR = "/data"; # DON'T CHANGE THIS
            };
            environmentFiles = [ cfg.secretsFile ];
            publishPorts = [ "${toString cfg.port}:3000" ];
            volumes = [ "${cfg.dataDir}:/data" ];
            networks = [ networks.karakeep.ref ];
          };
          serviceConfig.Restart = "always";
        };

        karakeep-chrome = {
          containerConfig = {
            image = "gcr.io/zenika-hub/alpine-chrome:124";
            exec = "--no-sandbox --disable-gpu --disable-dev-shm-usage --remote-debugging-address=0.0.0.0 --remote-debugging-port=9222 --hide-scrollbars";
            networks = [ networks.karakeep.ref ];
          };
          serviceConfig.Restart = "always";
        };

        karakeep-meilisearch = {
          containerConfig = {
            image = "docker.io/getmeili/meilisearch:v1.13.3";
            environments.MEILI_NO_ANALYTICS = "true";
            environmentFiles = [ cfg.secretsFile ];
            volumes = [ "${cfg.meiliDir}:/meili_data" ];
            networks = [ networks.karakeep.ref ];
          };
          serviceConfig.Restart = "always";
        };
      };
    };
  };
}
