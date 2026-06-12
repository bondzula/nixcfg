# Jellyfin media stack as podman quadlets.
# Replaces selfhosted/jellyfin/compose.yml (media-server, media-db, media-stats, media-requests).
{ config, ... }:

let
  inherit (config.virtualisation.quadlet) containers networks;
  # POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, JWT_SECRET
  # See jellystat.env.example. Read by podman (root), not baked into the store.
  secretsEnv = "/mnt/appdata/jellystat/secrets.env";
in
{
  virtualisation.quadlet = {
    # Replaces watchtower: containers with autoUpdate = "registry" are
    # re-pulled and restarted by the podman-auto-update timer.
    autoUpdate = {
      enable = true;
      calendar = "*-*-* 04:00:00";
    };

    networks.media = { };

    containers = {
      jellyfin = {
        containerConfig = {
          image = "docker.io/jellyfin/jellyfin:latest";
          autoUpdate = "registry";
          user = "1000";
          group = "1000";
          addGroups = [ "104" ]; # render, for QSV transcoding
          noNewPrivileges = true;
          devices = [ "/dev/dri/renderD128:/dev/dri/renderD128" ];
          publishPorts = [ "8096:8096" ];
          volumes = [
            "/mnt/appdata/jellyfin/config:/config"
            "/mnt/appdata/jellyfin/cache:/cache"
            "/mnt/media:/mnt/media"
          ];
          networks = [ networks.media.ref ];
        };
        serviceConfig.Restart = "always";
      };

      jellystat-db = {
        containerConfig = {
          image = "docker.io/library/postgres:15.2";
          user = "1000";
          group = "1000";
          environmentFiles = [ secretsEnv ];
          volumes = [ "/mnt/appdata/jellystat/db:/var/lib/postgresql/data" ];
          networks = [ networks.media.ref ];
          healthCmd = "pg_isready -U \"$POSTGRES_USER\"";
          # Unit only counts as started once postgres answers, so jellystat
          # (After/Requires below) waits for a ready database.
          notify = "healthy";
        };
        serviceConfig = {
          Restart = "always";
          TimeoutStartSec = "300";
        };
      };

      jellystat = {
        unitConfig = {
          After = [ containers.jellystat-db.ref ];
          Requires = [ containers.jellystat-db.ref ];
        };
        containerConfig = {
          image = "docker.io/cyfershepard/jellystat:latest";
          autoUpdate = "registry";
          user = "1000";
          group = "1000";
          environments = {
            POSTGRES_IP = "jellystat-db";
            POSTGRES_PORT = "5432";
          };
          environmentFiles = [ secretsEnv ];
          publishPorts = [ "3000:3000" ];
          volumes = [ "/mnt/appdata/jellystat/config:/app/backend/backup-data" ];
          networks = [ networks.media.ref ];
        };
        serviceConfig.Restart = "always";
      };

      jellyseerr = {
        containerConfig = {
          image = "docker.io/fallenbagel/jellyseerr:latest";
          autoUpdate = "registry";
          user = "1000";
          group = "1000";
          environments.TZ = "Europe/Belgrade";
          publishPorts = [ "5055:5055" ];
          volumes = [ "/mnt/appdata/jellyseerr/config:/app/config" ];
          networks = [ networks.media.ref ];
        };
        serviceConfig.Restart = "always";
      };
    };
  };
}
