# harkonnen — download clients

Unprivileged NixOS LXC on Proxmox running the download clients as rootful
podman quadlets, enabled via `nixosModules.selfhosted` in `default.nix` (modules live in `modules/nixos/selfhosted/`).

| Service   | Port | URL                          |
| --------- | ---- | ---------------------------- |
| rdtclient | 6500 | rdt.local.bondzulic.com      |
| sabnzbd   | 8080 | sabnzbd.local.bondzulic.com  |
| zurg      | 9999 | zurg.local.bondzulic.com     |

Zurg maintains the AllDebrid library index and serves authenticated WebDAV.
`disable_stream_proxy = true` makes file reads redirect to AllDebrid:
Infuse fetches the video from AllDebrid directly, bypassing Harkonnen and
Corrino. Infuse must support/follow these redirects and be able to reach
AllDebrid. No rclone mount or media download directory is created here.
Automatic ffprobe analysis is enabled for newly indexed torrents. It reads
parts of media files through Harkonnen to extract codecs, resolution and tracks,
so there is some server bandwidth/CPU usage even though playback is redirected.
It enriches metadata; it is not a complete media-integrity check.
Automatic repair is enabled every 60 minutes with `restrict_repair_to_cached`
enabled; Zurg can restart/re-add broken torrents on AllDebrid. Automatic
deletion stays disabled. Repairs depend on upstream content availability and
cannot guarantee every torrent remains playable.
The index is refreshed every 60 seconds. Adding new acquisitions through Zurg's
download-client/watchlist features is disabled for this provider; repairs of
existing entries are enabled separately. Logging uses INFO. The image does not
opt into automatic updates.

### Library folders

The WebDAV root contains `Movies`, `TV`, and `Anime`, created by Zurg filters.
They share the `media` group, so a torrent appears in exactly one of these:

- `Anime` (first): anime release-group markers or bracketed CRC32 checksums
  in torrent/file names. An explicit `Akira.1988` rule covers the existing
  anime movie, whose release uses normal movie naming.
- `TV` (second): Zurg's episode detection (`has_episodes`).
- `Movies` (last): everything not matched by the first two filters.

These are naming heuristics, not an authoritative genre lookup. An anime
release without recognisable markers may land in TV or Movies; add a title
rule when needed. Movies is a fallback, so unrelated non-series media can also
appear there. File contents are not moved or downloaded to make these folders.
The original `all` aggregate view is retained. In Infuse, favourite/index the
three category folders rather than the whole root plus `all`, to avoid duplicate
library scans.

**AllDebrid requires Zurg's sponsor-only nightly**, currently
`ghcr.io/debridmediamanager/zurg:latest`. The public stable v1.0.0 image only
supports Real-Debrid. Obtain upstream sponsor access and link your GitHub account
at https://gatekeeper.debridmediamanager.com before deploying. The `zurg.image`
option can pin a specific nightly tag from the private upstream releases.

The generated config is mounted read-only: change configuration through Nix,
not the Zurg dashboard. Credentials are injected at service startup into
`/run/zurg/config.yml`, never stored in the Nix store. Index state persists in
`/mnt/appdata/zurg/data`.

### Infuse setup

After rebuilding Harkonnen and Corrino, ensure `zurg.local.bondzulic.com`
resolves to Corrino (`192.168.1.10`) from the Infuse device (LAN/VPN DNS).
Add a WebDAV (HTTPS) share with:

- Address: `zurg.local.bondzulic.com`
- Port: `443`
- Path: `/infuse/` (Zurg's Infuse-specific WebDAV endpoint)
- Username/password: the values in `ZURG_USERNAME` / `ZURG_PASSWORD`

For clients outside the LAN, provide VPN access to Corrino or an appropriate
reachable HTTPS hostname. This local hostname alone does not provide remote access.
Keep the playback client local: mounting Zurg on this remote server and then
streaming the mount through Jellyfin would put the server back in the data path.

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

rdtclient and SABnzbd do not take secrets via environment. Zurg requires an
AllDebrid API key and separate WebDAV credentials (do not commit them).
The WebDAV username/password protect Infuse access; they are not your AllDebrid
account login.

On Harkonnen, `/mnt/appdata` belongs to `bondzula`, so create/edit these files
as your regular user, without sudo:

```sh
mkdir -p /mnt/appdata/zurg
chmod 700 /mnt/appdata/zurg
touch /mnt/appdata/zurg/secrets.env
chmod 600 /mnt/appdata/zurg/secrets.env
nvim /mnt/appdata/zurg/secrets.env
```

Contents (systemd EnvironmentFile syntax; quote values containing spaces):

```ini
ZURG_AD_TOKEN=your-alldebrid-api-key
ZURG_USERNAME=infuse
ZURG_PASSWORD=your-unique-webdav-password
```

Get the key from https://alldebrid.com/apikeys. A missing or blank value
prevents Zurg from starting. To rotate credentials, edit the file and run
`sudo systemctl restart zurg`.

The rootful system service can read your user-owned mode-0600 files. No manual
sudo is needed to manage them; NixOS rebuilds and restarting the system service
still require sudo. Files inside the container's index directory may be written
as root, so manual maintenance of those files may require sudo.

### Private image access

Separately from the AllDebrid key, authenticate to GHCR using the GitHub account
granted upstream sponsor access and a personal access token (classic) with
`read:packages`. Run as `bondzula` on Harkonnen; enter the GitHub token at the
password prompt:

```sh
podman login --authfile /mnt/appdata/zurg/registry-auth.json \
  --username YOUR_GITHUB_USERNAME ghcr.io
chmod 600 /mnt/appdata/zurg/registry-auth.json
```

The rootful Zurg Quadlet explicitly uses this file when pulling its private
image. A login to your regular user's default Podman auth store alone would
not authenticate the rootful service. Both credential files stay outside Git.

### Deploy and verify

Deployment uses Git and GitHub. On your development machine, review and commit
the Zurg files explicitly (there may be unrelated changes in the working tree):

```sh
cd /Users/bondzula/Developer/nixcfg
git add modules/nixos/selfhosted/zurg.nix \
  modules/nixos/selfhosted/default.nix \
  hosts/harkonnen/default.nix hosts/harkonnen/README.md \
  hosts/corrino/config/Caddyfile
git diff --cached
git commit -m "Add AllDebrid Zurg index on Harkonnen"
git push origin main
```

On Harkonnen, pull the committed configuration after setting up credentials:

```sh
cd ~/nixcfg
git pull --ff-only origin main
sudo nixos-rebuild switch --flake .#harkonnen
sudo systemctl status zurg
sudo journalctl -u zurg -n 50 --no-pager
```

On Corrino, pull and rebuild the reverse proxy configuration too:

```sh
cd ~/nixcfg
git pull --ff-only origin main
sudo nixos-rebuild switch --flake .#corrino
```

These commands assume clean host checkouts. If Git reports local modifications,
review them before pulling; do not discard host changes blindly. No file copying
over SSH or remote `git add` is needed.

Verify listings and a file redirect (curl prompts for the WebDAV password):

```sh
curl --user infuse -X PROPFIND -H 'Depth: 1' https://zurg.local.bondzulic.com/dav/
# Replace the path with a URL-encoded media file from the listing.
# Do not add -L: verify the redirect without downloading the video.
curl --user infuse --range 0-0 --dump-header - --output /dev/null \
  'https://zurg.local.bondzulic.com/dav/all/<torrent>/<file>'
```

The file request should return a redirect with an AllDebrid download URL in
`Location`. Treat that signed URL as a secret. During Infuse playback, verify
that server bandwidth does not scale with the video's bitrate.

AllDebrid may require email confirmation of a new API sign-in. If the service
logs `AUTH_BLOCKED`, check your AllDebrid email/account and approve the new
location before retrying. A `NO_SERVER` response indicates AllDebrid rejected
the server/VPN IP; direct-stream redirects do not bypass API access restrictions.
See [AllDebrid API errors](https://docs.alldebrid.com/).

References: [configuration](https://notes.debridmediamanager.com/reference/config/),
[nightly access](https://github.com/debridmediamanager/zurg-public#download),
[GHCR authentication](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

## Operating

Containers are rootful — `sudo podman ps|logs|exec`, or `journalctl -u sabnzbd`.

- Status: `systemctl status rdtclient sabnzbd zurg`
- Updates: `podman-auto-update.timer` daily at 04:00, both containers opt in
  (matching the old watchtower labels).
- rdtclient's database lives directly in `/mnt/appdata` (mounted as
  `/data/db`), carried over as-is from the compose file.
