# corrino — ingress & dashboards

Unprivileged NixOS LXC on Proxmox running the reverse proxy and monitoring
dashboards as rootful podman quadlets, enabled via `nixosModules.selfhosted` in `default.nix` (modules live in `modules/nixos/selfhosted/`). Also runs
Tailscale as a subnet router.

| Service           | Port    | URL                               |
| ----------------- | ------- | --------------------------------- |
| caddy             | 80, 443 | ingress for *.local.bondzulic.com |
| homepage          | 3000    | homepage.local.bondzulic.com      |
| speedtest-tracker | 8080    | speedtest.local.bondzulic.com     |
| uptime-kuma       | 3001    | uptime-kuma.local.bondzulic.com   |

## Network

Static IP `192.168.1.10/24` is managed by NixOS (`proxmoxLXC.manageNetwork =
true`), not by Proxmox. The Proxmox `net0` device still owns the bridge and
MAC — set its IPv4 mode to "Static" with no address. Recovery if networking
breaks: `pct enter <vmid>`, then `exec /run/current-system/sw/bin/bash
--login`, then `nixos-rebuild --rollback switch`.

## Caddy

The Caddyfile lives in this directory and is mounted read-only from the nix
store — edit it here and `nixos-rebuild switch` to apply (the container
restarts automatically). The image is `caddybuilds/caddy-cloudflare`
(Caddy + Cloudflare DNS plugin prebuilt), replacing the old local
Dockerfile/xcaddy build. TLS data persists in `/mnt/appdata/caddy/data`, so
certificates survive container replacement.

## Secrets

Created by hand, root-owned, chmod 600, must exist before first deploy
(units exit 125 otherwise — after fixing, `systemctl reset-failed <unit>`):

- `/mnt/appdata/caddy/secrets.env`: `CLOUDFLARE_EMAIL`, `CLOUDFLARE_API_TOKEN`
- `/mnt/appdata/speedtest/secrets.env`: `APP_KEY`

## Operating

Containers are rootful — `sudo podman ps|logs|exec`, or `journalctl -u caddy`.

- Status: `systemctl status caddy homepage speedtest-tracker uptime-kuma`
- Homepage's docker integration talks to the podman socket
  (`/run/podman/podman.sock`, mounted as `/var/run/docker.sock`); it only
  sees containers on this host.
- Homepage's dashboard YAML can live in this repo: copy the files from
  `/mnt/appdata/homepage` into `./config/homepage/` and set
  `homepage.configDir = ./config/homepage;` in `default.nix` — they get
  mounted read-only over the writable data dir (which keeps logs/state).
  Until then the config stays mutable on the host (TODO).
- Updates: `podman-auto-update.timer` daily at 04:00 — only homepage opts in
  (matching the old watchtower labels). Caddy/speedtest/uptime-kuma are
  updated manually: `sudo podman pull <image> && sudo systemctl restart <unit>`.

## Tailscale

Tailscale runs in server mode, so IP forwarding is configured automatically.
After provisioning, bring it up with:

```bash
sudo tailscale up --advertise-routes=192.168.0.0/24
```
