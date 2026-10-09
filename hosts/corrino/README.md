# corrino — ingress & dashboards

Unprivileged NixOS LXC on Proxmox running Caddy, Homepage and Uptime Kuma
as rootful Podman quadlets. Tailscale advertises `192.168.1.0/24`.

| Service | Published address | URL |
| --- | --- | --- |
| Caddy | TCP 80/443, UDP 443 | ingress for active `*.local.bondzulic.com` services |
| Homepage | `10.88.0.1:3000` (container bridge only) | homepage.local.bondzulic.com |
| Uptime Kuma | `10.88.0.1:3001` (container bridge only) | uptime-kuma.local.bondzulic.com |

## Network

NixOS owns `192.168.1.10/24`, gateway/DNS `192.168.1.1`.
`proxmoxLXC.manageNetwork = true`; Proxmox supplies only the bridge/MAC.
Set Proxmox net0 IPv4 to "Static" with no address.
The NixOS firewall permits SSH, HTTP, HTTPS/HTTP3 and Tailscale. Dashboard
ports are bound to the Podman bridge, which Caddy uses to reach them.

Recovery from Proxmox: `pct enter <vmid>`, then
`exec /run/current-system/sw/bin/bash --login` and
`nixos-rebuild --rollback switch`. A Kuma major-version rollback also
requires a compatible database; do not start an older image against a
migrated database.

## Containers and configuration

The Caddyfile lives in `config/Caddyfile` and is mounted read-only from the
Nix store. Changes restart Caddy on rebuild. Caddy's image digest is pinned
in `default.nix`; Kuma's version is pinned in its shared module. Homepage
uses `latest` and the daily Podman auto-update timer, with HTTP health checks
and readiness notification. Caddy also has an HTTP health check. Kuma's
health check checks HTTP availability without killing long-running migrations.

Caddy's admin API binds to localhost inside its container. It is not
available to Homepage or the LAN. Homepage has no container-engine socket
mount or Caddy admin widget. Its mutable YAML remains in
`/mnt/appdata/homepage` because it contains private widget credentials; do
not copy those files into Git. Restrict YAML files to mode 600.

TLS state persists at `/mnt/appdata/caddy/data` and runtime config at
`/mnt/appdata/caddy/config`. The DNS-challenge environment file
`/mnt/appdata/caddy/secrets.env` contains `CLOUDFLARE_EMAIL` and
`CLOUDFLARE_API_TOKEN`; it must be root-owned and mode 600.

Containers require their state mounts before starting. Use ordinary
password-protected sudo for administration:

```bash
sudo podman ps
systemctl status caddy homepage uptime-kuma
journalctl -u caddy
sudo podman healthcheck run caddy
sudo podman healthcheck run homepage
sudo podman healthcheck run uptime-kuma
```

Only root is trusted by the Nix daemon. The SSH user belongs to wheel,
without Podman socket access. Sudo remains password-protected.

## Updates

For Caddy updates, pull the intended image, verify its version/digest and
update `caddy.image` in `default.nix`. For Kuma updates, set its explicit
image version, back up its data, then rebuild. Follow the upstream v1-to-v2
migration guide for existing v1 databases and do not interrupt migration.
`system.stateVersion` tracks installation compatibility and is intentionally
unchanged by package updates.

## Tailscale

IP forwarding is enabled by server mode. Existing route advertisement is
persisted by Tailscale; initial setup uses:

```bash
sudo tailscale up --advertise-routes=192.168.1.0/24
```

Approve the advertised route in the Tailscale administration console.
