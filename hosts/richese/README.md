# richese — *arr stack

Unprivileged NixOS LXC on Proxmox running the media automation stack as
rootful podman quadlets, configured via `nixosModules.selfhosted.arr` in
`default.nix` (module: `modules/nixos/selfhosted/arr.nix`, instances as submodules).

| Service      | Port | URL                               |
| ------------ | ---- | --------------------------------- |
| prowlarr     | 9696 | prowlarr.local.bondzulic.com      |
| flaresolverr | —    | internal (http://flaresolverr:8191) |
| radarr-hd    | 7878 | radarr-hd.local.bondzulic.com     |
| radarr-uhd   | 7879 | radarr-uhd.local.bondzulic.com    |
| sonarr-hd    | 8989 | sonarr-hd.local.bondzulic.com     |
| sonarr-uhd   | 8990 | sonarr-uhd.local.bondzulic.com    |
| sonarr-anime | 8991 | sonarr-anime.local.bondzulic.com  |
| bazarr-hd    | 6767 | bazarr-hd.local.bondzulic.com     |
| bazarr-uhd   | 6768 | bazarr-uhd.local.bondzulic.com    |
| bazarr-anime | 6769 | bazarr-anime.local.bondzulic.com  |
| zilean (+ zilean-db) | 8181 | —                          |
| notifiarr    | 5454 | notifiarr.local.bondzulic.com     |

All containers share the `arr` podman network, and names are unchanged from
the compose setup — URLs stored inside the apps (prowlarr → flaresolverr,
prowlarr → radarr/sonarr, etc.) keep resolving.

## Network

Static IP `192.168.1.41/24` is managed by NixOS (`proxmoxLXC.manageNetwork =
true`), not by Proxmox. The Proxmox `net0` device still owns the bridge and
MAC — set its IPv4 mode to "Static" with no address. Recovery if networking
breaks: `pct enter <vmid>`, then `exec /run/current-system/sw/bin/bash
--login`, then `nixos-rebuild --rollback switch`.

## Secrets

Created by hand, root-owned, chmod 600, must exist before first deploy
(units exit 125 otherwise — after fixing, `systemctl reset-failed <unit>`):

- `/mnt/appdata/zilean/secrets.env`: `POSTGRES_PASSWORD` (shared by zilean
  and zilean-db; value from the old `selfhosted/arr/.env`)

## Operating

Containers are rootful — `sudo podman ps|logs|exec`, or `journalctl -u prowlarr`.

- Status: `systemctl status prowlarr radarr-hd sonarr-hd bazarr-hd zilean notifiarr` (etc.)
- Startup ordering: zilean waits for a healthy zilean-db (`Notify=healthy`).
- Updates: `podman-auto-update.timer` daily at 04:00 — the whole stack opts
  in (matching the old watchtower labels).
- App configs under `/mnt/appdata/<container-name>`; media under `/mnt/media`.
