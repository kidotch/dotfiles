#!/usr/bin/env bash
set -e

echo "[1/5] Install locales"
apt update
apt install -y locales

echo "[2/5] Generate C.UTF-8"
locale-gen C.UTF-8

echo "[3/5] Set default locale"
update-locale LANG=C.UTF-8

echo "[4/5] Export locale for current shell"
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

echo "[5/5] Kill tmux server (if exists)"
tmux kill-server 2>/dev/null || true

echo "Done. Please re-SSH and start tmux again."
