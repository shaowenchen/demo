#!/usr/bin/env bash
set -euo pipefail

ssh-keygen -A
mkdir -p /var/run/sshd
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_rsa /root/.ssh/authorized_keys

exec /usr/sbin/sshd -D -e
