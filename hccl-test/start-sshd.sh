#!/usr/bin/env bash
set -euo pipefail

SSH_PORT="${SSH_PORT:-8822}"

ssh-keygen -A
mkdir -p /var/run/sshd
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_rsa /root/.ssh/authorized_keys

cat > /root/.ssh/config <<EOF
Host *
  Port ${SSH_PORT}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF
chmod 600 /root/.ssh/config

echo "Starting sshd on port ${SSH_PORT}"
exec /usr/sbin/sshd -D -e -p "${SSH_PORT}"
