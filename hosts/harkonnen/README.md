# harkonnen — download clients

Unprivileged NixOS LXC on Proxmox running the download clients as rootful
podman quadlets, enabled via `nixosModules.selfhosted` in `default.nix` (modules live in `modules/nixos/selfhosted/`).

| Service   | Port | URL                          |
| --------- | ---- | ---------------------------- |
| rdtclient | 6500 | rdt.local.bondzulic.com      |
| sabnzbd   | 8080 | sabnzbd.local.bondzulic.com  |

gluetun + qbittorrent are intentionally not migrated — they were not live
under the compose setup either. When they come back, the quadlet pattern is:
gluetun with `NET_ADMIN`+`NET_RAW` caps and `/dev/net/tun`, qbittorrent with
`Network=gluetun.container` and `BindsTo=gluetun.service` (no pod), ports
published on gluetun.

## Network

Static IP `192.168.1.40/24` is managed by NixOS (`proxmoxLXC.manageNetwork =
true`), not by Proxmox. The Proxmox `net0` device still owns the bridge and
MAC — set its IPv4 mode to "Static" with no address. Recovery if networking
breaks: `pct enter <vmid>`, then `exec /run/current-system/sw/bin/bash
--login`, then `nixos-rebuild --rollback switch`.

## Secrets

None — neither service takes secrets via environment.

## Operating

Containers are rootful — `sudo podman ps|logs|exec`, or `journalctl -u sabnzbd`.

- Status: `systemctl status rdtclient sabnzbd`
- Updates: `podman-auto-update.timer` daily at 04:00, both containers opt in
  (matching the old watchtower labels).
- rdtclient's database lives directly in `/mnt/appdata` (mounted as
  `/data/db`), carried over as-is from the compose file.
