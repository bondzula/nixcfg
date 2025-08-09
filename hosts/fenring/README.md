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
# Container parameters
ctid="111"
ctname="fenring"
ctt="local:vztmpl/nixos-system-x86_64-linux.tar.xz"
cts="local-flash"

# Create the container with static IP
pct create ${ctid} ${ctt} \
  --hostname=${ctname} \
  --ostype=nixos --unprivileged=0 --features nesting=1 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.0.11/24,gw=192.168.0.1 \
  --arch=amd64 --swap=1024 --memory=8192 \
  --storage=${cts} --rootfs ${cts}:20

# No need to resize since we're allocating 20G upfront
```

### 2. Add Backup Storage Mount Point

Before starting the container, add your backup storage as a bind mount:

```bash
# Stop container if running
pct stop ${ctid}

# Edit the container config
nano /etc/pve/lxc/${ctid}.conf

# Add this line (adjust the host path to your actual backup storage):
mp0: /path/to/your/backup/storage,mp=/mnt/backups

# Start the container
pct start ${ctid}
```

### 3. Initial Container Setup

Enter the container and prepare it:

```bash
# Enter the container
pct enter ${ctid}

# Source the environment
source /etc/set-environment

# Delete the default root password (we'll use SSH keys)
passwd --delete root

# Only needed if you plan to deploy locally (Option B)
# nix-env -iA nixos.git
```

### 4. Deploy Your Configuration

You have several options for deployment:

#### Option A: Remote Build and Deploy from macOS (Recommended)

Since you're on macOS, the easiest approach is to SSH into the container and build there while using your local flake:

```bash
# From your local machine, copy your flake to the container
cd /path/to/nixcfg
rsync -av --exclude='.git' --exclude='result' . root@192.168.0.11:/tmp/nixcfg/

# SSH into the container and deploy
ssh root@192.168.0.11
cd /tmp/nixcfg
nixos-rebuild switch --flake .#fenring
```

#### Option B: Build locally and copy (Advanced)

If you have Nix installed on macOS, you can build locally and copy:

```bash
# From your local machine where you have the nixcfg repo
cd /path/to/nixcfg

# Build the configuration locally (requires linux builder on macOS)
nix build .#nixosConfigurations.fenring.config.system.build.toplevel

# Copy the built system to the container and activate it
nix copy --to ssh://root@192.168.0.11 ./result
ssh root@192.168.0.11 "./result/bin/switch-to-configuration switch"
```

Note: This requires a Linux builder configured on your macOS system.

#### Option C: Local Deployment from within the container

Deploy from within the container itself:

```bash
# Remove default configuration
rm -rf /etc/nixos/*

# Clone your nixcfg repository
git clone https://github.com/bondzula/nixcfg /etc/nixos
cd /etc/nixos

# Build and switch to the fenring configuration
nixos-rebuild switch --flake .#fenring
```

### 5. Configure Samba Password

After the rebuild completes, set up the Samba password for your user:

```bash
# The user 'bondzula' was created by the configuration
# Set the Samba password (can be different from system password)
smbpasswd -a bondzula
```

### 6. Verify Services

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

### 7. Network Configuration

The container is configured with static IP `192.168.0.11`.

Test SSH access from your host machine:

```bash
ssh bondzula@192.168.0.11
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
