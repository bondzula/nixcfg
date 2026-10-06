# atreides — applications

Unprivileged NixOS LXC on Proxmox with Intel GPU passthrough, running the
main self-hosted applications as rootful podman quadlets, enabled via `nixosModules.selfhosted` in
`default.nix` (modules live in `modules/nixos/selfhosted/`).

| Service                 | Port       | URL                            |
| ----------------------- | ---------- | ------------------------------ |
| immich-server           | 2283       | immich.local.bondzulic.com     |
| immich-machine-learning | —          | internal (openvino)            |
| immich-db / immich-redis| —          | internal                       |
| gitea (+ gitea-db)      | 3000, 2222 | gitea.local.bondzulic.com      |
| paperless (+ db, broker)| 8000       | paperless.local.bondzulic.com  |
| karakeep (+ chrome, meilisearch) | 3050 | karakeep.local.bondzulic.com |
| grocy                   | 9283       | grocy.local.bondzulic.com      |
| racuni                  | 8080       | http://192.168.1.20:8080       |

TODO: bookworm is not yet defined here (it had no compose file in the old
selfhosted repo either).

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
- `/mnt/appdata/gitea/secrets.env`:
  `GITEA__database__USER`/`POSTGRES_USER`,
  `GITEA__database__PASSWD`/`POSTGRES_PASSWORD`,
  `GITEA__database__NAME`/`POSTGRES_DB`
- `/mnt/appdata/paperless/secrets.env`: the old compose `.env` contents
  (PAPERLESS_URL, PAPERLESS_SECRET_KEY, OCR settings, PAPERLESS_DB*) plus
  matching `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`.
  `PAPERLESS_DBHOST` is overridden to `paperless-db` in nix.
- `/mnt/appdata/karakeep/secrets.env`:
  `NEXTAUTH_SECRET`, `NEXTAUTH_URL`, `MEILI_MASTER_KEY`

## Operating

Containers are rootful — `sudo podman ps|logs|exec`, or `journalctl -u immich-server`.

- Status: `systemctl status immich-server immich-db gitea paperless karakeep grocy`
- Startup ordering: immich-server waits for healthy db+redis; paperless for
  healthy db+broker; gitea for healthy db (quadlet `Notify=healthy`).
- App data under `/mnt/appdata/<app>`; immich uploads in `/mnt/immich`;
  gitea repos in `/mnt/gitea`; paperless documents in `/mnt/paperless`.

## Updates

### Racuni

Application source and CI live in `bondzula/racuni`. CI publishes tested private
amd64 images to `ghcr.io/bondzula/racuni`; the exact production digest is pinned
in `racuni-image.nix`. Updates are explicit, not automatic.

The original production database is bind-mounted from `/srv/racuni/data`, owned
by UID/GID 65532. Do not replace this with an anonymous volume. Startup refuses a
missing or empty database, checks integrity, and saves a consistent SQLite
snapshot to `/srv/racuni/deploy-backups` before running migrations. Another
container with a writable mount of the same data directory prevents startup.

Before first deployment, run `sudo ./deploy/configure-atreides.sh` from the
racuni checkout (or `sudo ~/racuni-deploy-setup/configure-atreides.sh` from the
prepared server copy). It prompts for a classic GitHub token with
`read:packages` and an app login password; both stay in root-owned files under
`/mnt/appdata/racuni`, outside Git and the Nix store.

For an update, preview the new image against a consistent database snapshot,
update `racuni-image.nix`, commit/push, then on atreides:

```sh
cd ~/nixcfg
git pull --ff-only
sudo ./scripts/deploy-racuni.sh
```

Check `systemctl status racuni` and `journalctl -u racuni`. The app's daily
snapshots remain in `/srv/racuni/data/backups`; `mise run backup:pull` from the
racuni checkout on your computer copies them off-host. This is an explicit
backup pull, not a background schedule. Pre-start snapshots are root-owned and
are not pruned by the application's 60-snapshot retention.

If a release migrated the schema, rollback may require both a previous image
and its pre-start database snapshot. Stop writers and preserve the entire
database directory including WAL/SHM before restoring. See `racuni/deploy/README.md`
for the complete preview, backup, and restore procedure.

### Other applications

Nothing on this host auto-updates (matching the old watchtower label setup).

- Immich (mind breaking releases — read release notes first):
  `sudo podman pull ghcr.io/immich-app/immich-server:release ghcr.io/immich-app/immich-machine-learning:release-openvino`
  then `sudo systemctl restart immich-server immich-machine-learning`.
  To pin a version instead, set `immich.serverImage`/`immich.mlImage` in `default.nix`.
- Gitea/meilisearch: set `gitea.image` in `default.nix` (or bump the default in `modules/nixos/selfhosted/`) and rebuild.
- Paperless/grocy/karakeep: `sudo podman pull <image> && sudo systemctl restart <unit>`.

## Hardware acceleration

immich-server (quicksync transcoding) and immich-machine-learning (openvino)
both get `/dev/dri`. Host-side Intel drivers are installed via
`hardware.graphics` in `default.nix`. Verify after deploy: upload a video,
check `journalctl -u immich-machine-learning` for openvino init, and smart
search should hit the GPU. `intel_gpu_top` only works on the Proxmox host,
not inside the LXC.

## Migration notes

- The meilisearch index and immich ML model cache lived in named docker
  volumes and are not migrated — the model cache re-downloads on demand, and
  karakeep can rebuild its index (admin settings → reindex all bookmarks).
- Immich's `UPLOAD_LOCATION=/mnt/immich` and `DB_DATA_LOCATION=/mnt/appdata/immich/db`
  are now the `immich.uploadLocation`/`immich.dbDataLocation` options — verify they match the live
  `.env` on this host before the first rebuild.
