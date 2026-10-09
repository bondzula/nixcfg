# atreides — applications

Unprivileged NixOS LXC on Proxmox with Intel GPU passthrough, running
Immich and Racuni as rootful podman quadlets, plus SMB file sharing.
Apps are enabled via `nixosModules.selfhosted` in
`default.nix` (modules live in `modules/nixos/selfhosted/`).

| Service                 | Port       | URL                            |
| ----------------------- | ---------- | ------------------------------ |
| immich-server           | 2283       | immich.local.bondzulic.com     |
| immich-machine-learning | —          | internal (openvino)            |
| immich-db / immich-redis| —          | internal                       |
| racuni                  | 8080       | http://192.168.1.20:8080       |

## Network

Static IP `192.168.1.20/24` is managed by NixOS (`proxmoxLXC.manageNetwork =
true`), not by Proxmox. The Proxmox `net0` device still owns the bridge and
MAC — set its IPv4 mode to "Static" with no address. Recovery if networking
breaks: `pct enter <vmid>`, then `exec /run/current-system/sw/bin/bash
--login`, then `nixos-rebuild --rollback switch`.

## Secrets

Created by hand, root-owned, chmod 600, must exist before first deploy
(units exit 125 otherwise — after fixing, `systemctl reset-failed <unit>`).
Because there is no compose interpolation anymore, files carry both the app
and postgres spellings of the same values — the pairs must match:

- `/mnt/appdata/immich/secrets.env`:
  `DB_USERNAME`/`POSTGRES_USER`, `DB_PASSWORD`/`POSTGRES_PASSWORD`,
  `DB_DATABASE_NAME`/`POSTGRES_DB`

## Operating

Containers are rootful — `sudo podman ps|logs|exec`, or `journalctl -u immich-server`.

- Status: `systemctl status immich-server immich-machine-learning immich-db immich-redis racuni samba-smbd samba-wsdd`
- Immich starts after its database and cache become healthy.
- Immich uploads live in `/mnt/immich/uploads`, and app state in `/mnt/appdata/immich`.
- SMB shares are `/mnt/bondzula`, `/mnt/courses`, and `/mnt/media`.

Gitea, Paperless, Karakeep and Grocy are no longer enabled on this host.
Their stored data and secrets are retained under `/mnt/appdata`, `/mnt/gitea`
and `/mnt/paperless`; they are not active services. Shared app modules remain
available for other hosts.

## SMB

Windows discovery advertises the server only on `eth0`. Discovery scanning
is disabled; advertising shares to Windows clients still works. This keeps
wsdd away from temporary Podman bridges and veth interfaces.

Mac Finder metadata uses extended attributes (`fruit:metadata = stream`),
while resource forks use `._` AppleDouble companion files
(`fruit:resource = file`) to avoid Linux's per-xattr size limit. Preserve
these companion files when moving or copying data outside SMB.

Before switching resource storage on 2026-10-09, all three share trees were
scanned without errors: no `AFP_Resource` xattr streams were present, so no
resource-fork migration was needed. Media already contained three AppleDouble
files. If changing storage modes again, inspect existing resource forks first.
An isolated loopback SMB test on the Bondzula ZFS mount verified a 128 KiB
resource fork round trip and the corresponding AppleDouble file contents.

## Updates

### Racuni

GitHub Actions in `bondzula/racuni` publishes tested private amd64 images to
`ghcr.io/bondzula/racuni:latest` after every successful main build. The racuni
Quadlet opts into Podman's native registry auto-updates. On atreides,
`podman-auto-update.timer` checks every five minutes, pulls changed images,
and restarts their systemd services. Other applications remain opted out.

The service starts at boot, publishes port 8080, and uses the original
`/srv/racuni/data` bind mount as UID/GID 65532. Native `ExecStartPre` commands
refuse a missing/empty database and take a consistent SQLite snapshot to
`/srv/racuni/deploy-backups` before migrations. No deployment scripts are used.

Credentials already configured under `/mnt/appdata/racuni` are reused. The
service and auto-updater explicitly use `registry-auth.json`. A tmpfiles
symlink makes the same auth available at root's standard Docker-compatible
credential location, without replacing an existing root auth file.

Install host configuration changes using your normal workflow:

```sh
cd ~/nixcfg
git pull --ff-only
sudo nixos-rebuild switch --flake .#atreides
```

After installation, application changes need only a push to racuni's main
branch. For an immediate update or a manual pull:

```sh
sudo systemctl start podman-auto-update.service
# Alternatively:
sudo podman pull ghcr.io/bondzula/racuni:latest
sudo systemctl restart racuni
```

Inspect with `systemctl status racuni`, `journalctl -u racuni`, and
`systemctl list-timers podman-auto-update`. App snapshots remain under
`/srv/racuni/data/backups` (60 retained); pre-start snapshots are kept separately.
Copy consistent snapshots off-host using normal SSH/SCP or your backup tool.

Podman can revert an image when startup fails, but database migrations are not
reverted automatically. Preserve the stopped database including WAL/SHM before
restoring a compatible snapshot and image. Set `racuni.autoUpdate = false` and
select an older image tag while investigating a rollback. See `racuni/deploy/README.md`.

### Immich

Immich does not opt into automatic image updates.

- Immich is pinned to v3.3.0, with the Postgres and Valkey images from that
  release's compose file. Read release notes, back up the database, update
  `immich.serverImage`/`immich.mlImage` and the upstream dependency digests in
  `default.nix`, then rebuild. Keep the server and ML versions matched.

## Hardware acceleration

immich-server (quicksync transcoding) and immich-machine-learning (openvino)
both get `/dev/dri`. Host-side Intel drivers are installed via
`hardware.graphics` in `default.nix`. Both containers receive the host's
`render` and `video` supplementary group IDs; this is required when LXC
maps GPU ownership to `nobody`. Also select Quick Sync in Immich's
admin video transcoding settings; passing the device alone does not enable
hardware transcoding. Verify after deploy: upload a video,
check `journalctl -u immich-machine-learning` for openvino init, and smart
search should hit the GPU. `intel_gpu_top` only works on the Proxmox host,
not inside the LXC.

## Migration notes

- Immich ML model cache can be re-downloaded on demand.
- Immich's `UPLOAD_LOCATION=/mnt/immich/uploads` and `DB_DATA_LOCATION=/mnt/appdata/immich/db`
  are now the `immich.uploadLocation`/`immich.dbDataLocation` options — verify they match the live
  `.env` on this host before the first rebuild.
  `/mnt/immich` is the ZFS dataset mount; its `uploads` child contains all six
  storage directories and their `.immich` markers. Mounting the dataset root
  as `/data` causes Immich's folder checks to fail. Correct the mount path
  instead of creating markers in the wrong directory or disabling checks.
