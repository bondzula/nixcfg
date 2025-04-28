# Vernius

A proxmox LXC container serving my media content.

- Jellyfin
- Jellyseerr
- Audiobookshelf

## Setup

- Follow this totorial on how to setup NixOS LXC contaienr under proxmox https://nixos.wiki/wiki/Proxmox_Linux_Container
- Add required devices (/dev/net/tun, and /dev/dri) for Tailscale, and Hardware Transcoding
- Mount media drives
- Mount a RAM drive for transcoding


## Pending Tasks

- Add Audiobookshelf
- Use RAM for transcoding instead of the this (saves SSD's lifespan)


