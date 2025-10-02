# Fenring

A Proxmox LXC container serving as a NAS for backup storage using Samba.

## Features
- Samba share for network backups
- SSH access for remote management
- Automatic directory creation with proper permissions
- Windows network discovery support

## Setup Instructions

### 1. Create the LXC Container in Proxmox

Since you already have the NixOS template, create the container using the Proxmox CLI:

```bash
pct create 111 local:vztmpl/nixos-system-x86_64-linux.tar.xz \
  --hostname fenring \
  --cores 2 \
  --memory 8192 \
  --rootfs local-flash:20 \
  --unprivileged 1 \
  --features keyctl=1,nesting=1 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.0.11/24,gw=192.168.0.1 \
  --onboot 1
```

### 2. Add Backup Storage Mount Point

Before starting the container, add your backup storage as a bind mount:

```bash
# Add the mappings
pct set 111 -mp0 /zeus/backups,mp=/mnt/backups

# Edit the container config
nano /etc/pve/lxc/111.conf

# Add UID mappings at the bottom
lxc.idmap: u 0 100000 1000
lxc.idmap: g 0 100000 1000
lxc.idmap: u 1000 1000 1
lxc.idmap: g 1000 1000 1
lxc.idmap: u 1001 101001 64534
lxc.idmap: g 1001 101001 64534

# On proxmox, make sure /etc/subgid and /etc/subuid have the following:
root:1000:1

# Start the container
pct start 111
```

### 3. Initial Container Setup

Enter the container and prepare it:

```bash
# Enter the container
pct enter 111

# Source the environment
source /etc/set-environment

# Delete the default root password (we'll use SSH keys)
passwd --delete root

# Add git package
nix-channle --update

nix-shell -p git
```

### 4. Deploy Your Configuration

Deploy from within the container itself:

```bash
# Remove default configuration
rm -rf /etc/nixos/*

# Clone your nixcfg repository
git clone https://github.com/bondzula/nixcfg /etc/nixos
cd /etc/nixos

# Build and switch to the fenring configuration
nixos-rebuild switch --flake /etc/nixos#fenring
```

### 5. Verify Services

Check that everything is running correctly:

```bash
# Check Samba status
systemctl status smb nmb

# Test local Samba access
smbclient -L localhost -U bondzula

# Check SSH is running
systemctl status sshd

# Verify the backup directory exists with correct permissions
ls -la /mnt/backups
```

## Accessing the NAS

### From Windows
1. Open File Explorer
2. In the address bar, type: `\\192.168.0.11\Backups`
3. Enter credentials:
   - Username: `bondzula`
   - Password: (the Samba password you set)

### From macOS
1. In Finder, press Cmd+K
2. Enter: `smb://192.168.0.11/Backups`
3. Enter your credentials when prompted

### From Linux
1. Using file manager: `smb://192.168.0.11/Backups`
2. Using command line:
   ```bash
   # Mount the share
   sudo mkdir -p /mnt/fenring
   sudo mount -t cifs //192.168.0.11/Backups /mnt/fenring -o username=bondzula
   ```

## Troubleshooting

### Container won't start
- Check that unprivileged is set to 0: `pct config ${ctid} | grep unprivileged`
- Verify nesting is enabled: `pct config ${ctid} | grep features`

### Samba share not accessible
- Check firewall is not blocking: `iptables -L`
- Verify Samba is running: `systemctl status smb nmb`
- Check logs: `journalctl -u smb -u nmb`

### Permission issues with /mnt/backups
- The directory should be automatically created with 750 permissions
- Owner should be bondzula:bondzula
- If not, fix with: `chown -R bondzula:bondzula /mnt/backups`

### SSH access denied
- Verify your SSH key is correct in the configuration
- Check SSH service: `systemctl status sshd`
- Review SSH logs: `journalctl -u sshd`

## Maintenance

- **Logs**: Samba logs are in `/var/log/samba/`
- **Updates**: Run `nixos-rebuild switch --flake /etc/nixos#fenring` to update
- **Backups**: The `/mnt/backups` directory is bind-mounted from the Proxmox host
- **Configuration**: All settings are managed through `/etc/nixos/hosts/fenring/default.nix`
