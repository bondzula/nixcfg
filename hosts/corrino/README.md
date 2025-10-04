# Corrino host

Primarily used for network related services such as reverse proxy, tailscale, uptime monitoring, tunneling. However, it may also include some miscellanies services such as home page.

## Tailscale

Tailscale is running in a server mode, so IP forwarding should be automatically configured. All we have to do is run the `up` command with appropriate flags

```bash
sudo tailscale up --advertise-routes=192.168.0.0/24
```
