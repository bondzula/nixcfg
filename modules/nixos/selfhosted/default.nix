# Self-hosted applications as rootful podman quadlets.
#
# Usage (per host):
#   nixosModules.selfhosted = {
#     enable = true;            # pulls in podman + the auto-update timer
#     jellyfin = {
#       enable = true;
#       configDir = "/mnt/appdata/jellyfin/config";
#       ...
#     };
#   };
#
# Conventions shared by all app modules:
#   - every host path (state dirs, media, secrets files) is a required
#     option — hosts declare their mounts explicitly, no hidden defaults
#   - secrets are hand-placed env files (root-owned, chmod 600); a missing
#     file makes the unit exit 125 until `systemctl reset-failed <unit>`
#   - autoUpdate mirrors the old watchtower labels: apps that were
#     auto-updated default to autoUpdate = true, the rest are manual
{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.nixosModules.selfhosted;
in
{
  imports = [
    inputs.quadlet-nix.nixosModules.quadlet
    ./arr.nix
    ./caddy.nix
    ./gitea.nix
    ./grocy.nix
    ./homepage.nix
    ./immich.nix
    ./jellyfin.nix
    ./jellyseerr.nix
    ./jellystat.nix
    ./karakeep.nix
    ./paperless.nix
    ./rdtclient.nix
    ./sabnzbd.nix
    ./speedtest-tracker.nix
    ./uptime-kuma.nix
  ];

  options.nixosModules.selfhosted = {
    enable = lib.mkEnableOption "self-hosted applications as podman quadlets";

    timezone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Belgrade";
      description = "Timezone passed to containers.";
    };

    uid = lib.mkOption {
      type = lib.types.str;
      default = "1000";
      description = "UID containers run as / PUID for linuxserver.io images.";
    };

    gid = lib.mkOption {
      type = lib.types.str;
      default = "1000";
      description = "GID containers run as / PGID for linuxserver.io images.";
    };

    autoUpdate = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run the podman-auto-update timer (containers opt in individually).";
      };
      calendar = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 04:00:00";
        description = "Schedule for podman auto update, see systemd.time(7).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixosModules.podman.enable = true;

    virtualisation.quadlet.autoUpdate = {
      enable = cfg.autoUpdate.enable;
      calendar = cfg.autoUpdate.calendar;
    };
  };
}
