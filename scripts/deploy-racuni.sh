#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID != 0 ]]; then
  echo "Run this on atreides with sudo: sudo $0" >&2
  exit 1
fi
[[ $(hostname) == atreides ]] || { echo 'This deploy command is for atreides.' >&2; exit 1; }
repo=$(cd "$(dirname "$0")/.." && pwd)
auth=/mnt/appdata/racuni/registry-auth.json
env_file=/mnt/appdata/racuni/secrets.env
[[ -s /srv/racuni/data/racuni.db ]] || { echo 'Original production database is missing.' >&2; exit 1; }
[[ -s $auth && -f $env_file ]] || {
  echo 'Run racuni/deploy/configure-atreides.sh first to configure credentials.' >&2
  exit 1
}

# Build first, so a build failure leaves the existing application running.
nixos-rebuild build --flake "$repo#atreides"
echo 'Activating the built configuration. racuni takes a verified pre-start snapshot.'
nixos-rebuild switch --flake "$repo#atreides"
systemctl start racuni.service
for attempt in {1..60}; do
  if curl --fail --silent --show-error http://127.0.0.1:8080/healthz >/dev/null 2>&1; then
    systemctl status racuni.service --no-pager
    echo 'racuni is healthy at http://192.168.1.20:8080/'
    exit 0
  fi
  sleep 2
done
journalctl -u racuni.service -n 60 --no-pager
echo 'racuni health verification failed; inspect logs and the pre-start snapshot before rollback.' >&2
exit 1
