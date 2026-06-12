# vernius — media server

Unprivileged NixOS LXC on Proxmox with Intel GPU passthrough, running the
Jellyfin media stack as rootful podman quadlets, enabled via `nixosModules.selfhosted` in `default.nix` (modules live in `modules/nixos/selfhosted/`).

| Service      | Port | URL                              |
| ------------ | ---- | -------------------------------- |
| jellyfin     | 8096 | jellyfin.local.bondzulic.com     |
| jellystat    | 3000 | jellystat.local.bondzulic.com    |
| jellystat-db | —    | internal (postgres 15)           |
| jellyseerr   | 5055 | jellyseerr.local.bondzulic.com   |

## Network

Static IP `192.168.1.30/24` is managed by NixOS (`proxmoxLXC.manageNetwork =
true`), not by Proxmox. The Proxmox `net0` device still owns the bridge, VLAN
and MAC — set its IPv4 mode to "Static" with no address. If a rebuild breaks
networking, recover via the Proxmox console: `pct enter <vmid>`, then
`exec /run/current-system/sw/bin/bash --login`, then
`nixos-rebuild --rollback switch`.

## Deploying

```sh
sudo nixos-rebuild switch --flake .#vernius
```

## Secrets

Quadlet units read `/mnt/appdata/jellystat/secrets.env` (root-owned, chmod
600). It must exist before the first deploy, with the values the database was
created with:

```
POSTGRES_DB=...
POSTGRES_USER=...
POSTGRES_PASSWORD=...
JWT_SECRET=...
```

If it is missing, jellystat-db exits with code 125 until it hits the systemd
start limit; after creating the file run
`systemctl reset-failed jellystat-db jellystat && systemctl start jellystat-db jellystat`.

## Operating

Containers are rootful — always `sudo podman ps|logs|exec`. Plain `podman` as
a user is a separate (empty) rootless instance that cannot work in this LXC.

- Service status: `systemctl status jellyfin jellystat jellystat-db jellyseerr`
- Logs: `journalctl -u jellyfin -f`
- App data lives under `/mnt/appdata/<app>` (ZFS, mounted by Proxmox);
  media under `/mnt/media`.
- Image updates (replaces watchtower): `podman-auto-update.timer` runs daily
  at 04:00 and restarts containers whose `:latest` moved. Check with
  `systemctl list-timers podman-auto-update` and
  `journalctl -u podman-auto-update`.
- Startup ordering: jellystat waits for jellystat-db to pass `pg_isready`
  (quadlet `Notify=healthy`).

## Hardware transcoding

Jellyfin gets `/dev/dri/renderD128` plus the render group (gid 104). Verify:

```sh
sudo podman exec jellyfin /usr/lib/jellyfin-ffmpeg/vainfo \
  --display drm --device /dev/dri/renderD128
```

Expect the Intel iHD driver and a list of VAProfiles (H264/HEVC/VP9/AV1).
`intel_gpu_top` does not work inside an unprivileged LXC — run it on the
Proxmox host to watch the video engines instead.
