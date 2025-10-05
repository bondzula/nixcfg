# SMB

A Proxmox LXC container serving as Samba server.

## Setup Instructions

### 1. Create the LXC Container in Proxmox

Since you already have the NixOS template, create the container using the Proxmox CLI:

```bash
pct create {id} local:vztmpl/nixos-system-x86_64-linux.tar.xz \
  --hostname smb \
  --cores 2 \
  --memory 8192 \
  --rootfs flash:10 \
  --unprivileged 1 \
  --features keyctl=1,nesting=1 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.0.11/24,gw=192.168.0.1 \
  --onboot 1
```

### 2. Mount ZFS storage

Before starting the container, mount the ZFS pools used by samba.

```bash
# Add the mappings
pct set 200 -mp0 /zeus/smb/bondzula,mp=/mnt/bondzula

# Edit the container config
nano /etc/pve/lxc/200.conf

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
pct start 200
```

### 3. Initial Container Setup

Enter the container and prepare it:

```bash
# Enter the container
pct enter 200

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
# Clone your nixcfg repository
git clone https://github.com/bondzula/nixcfg && cd nixcfg

# Build and switch to the fenring configuration
nixos-rebuild switch --flake .#smb

# Remove the root version
cd ../ && rm -rf nixcfg
```

### 5. SSH as a regular user and pull the config

```bash
ssh bondzula@ip

git clone https://github.com/bondzula/nixcfg
```

### 6. Create the Samba user, and verify the shares

Check that everything is running correctly:

```bash
# Create a samba user
sudo smbpasswd -a bondzula

# Test local Samba access
smbclient -L localhost -U bondzula

# check the mount points
ls -la /mnt

# Reboot the instance
sudo reboot
```

## Accessing the NAS

### From Windows
1. Open File Explorer
2. In the address bar, type: `\\192.168.0.20\Bondzula`
3. Enter credentials:
   - Username: `bondzula`
   - Password: (the Samba password you set)

### From macOS
1. In Finder, press Cmd+K
2. Enter: `smb://192.168.0.11/Bondzula`
3. Enter your credentials when prompted

### From Linux
1. Using file manager: `smb://192.168.0.20/Bondzula`
2. Using command line:
   ```bash
   # Mount the share
   sudo mkdir -p /mnt/bondzula
   sudo mount -t cifs //192.168.0.20/Bondzula /mnt/bondzula -o username=bondzula
   ```

## Maintenance

- **Logs**: Samba logs are in `/var/log/samba/`
- **Updates**: Run `nixos-rebuild switch --flake .#smb` to update
