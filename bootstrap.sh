#!/bin/bash
set -euo pipefail

echo "🚀 BOOTSTRAP START"

# ---- vast.ai: disable auto tmux, use zellij instead ----
touch /root/.no_auto_tmux
# belt-and-suspenders: neutralize tmux auto-start in .bashrc directly
sed -i 's/tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux; exit/true/g' /root/.bashrc 2>/dev/null || true

# ---- Bootstrap wait gate: SSH login waits until bootstrap finishes ----
touch /root/.bootstrap_running
cat >> /root/.bashrc << 'WAIT_BLOCK'

# wait for bootstrap to finish before proceeding
if [ -f /root/.bootstrap_running ]; then
  echo "⏳ Bootstrap is still running... waiting for completion"
  while [ -f /root/.bootstrap_running ]; do sleep 2; done
  echo "✅ Bootstrap complete!"
  if [[ -x /usr/local/bin/zellij ]] && [[ -z "$ZELLIJ" ]] && [[ -n "$SSH_CONNECTION" ]]; then
    exec /usr/local/bin/zellij attach -c ssh_zellij
  fi
fi
WAIT_BLOCK

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y --no-install-recommends \
  ca-certificates curl git build-essential unzip tmux \
  gnupg dirmngr xz-utils

update-ca-certificates || true

# ---- Node.js (NodeSource) ----
# NodeSourceのsetupは今も使えるが、鍵や依存で失敗しがちなので前提を入れておく
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# npm グローバル先を user writable に（root環境でも安定する）
# ※ root運用を続けるならこのままでもOK。嫌なら消してもOK。
mkdir -p /root/.npm-global
npm config set prefix /root/.npm-global
export PATH="/root/.npm-global/bin:$PATH"
grep -q 'export PATH="/root/.npm-global/bin:$PATH"' /root/.bashrc 2>/dev/null || \
  echo 'export PATH="/root/.npm-global/bin:$PATH"' >> /root/.bashrc

# ---- Zellij ----
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"

curl -fL \
  https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz \
  -o zellij.tar.gz

tar -xzf zellij.tar.gz
# tarの中身が想定と違っても拾えるようにする
zellij_bin="$(find . -maxdepth 2 -type f -name zellij | head -n 1)"
if [ -z "${zellij_bin:-}" ]; then
  echo "❌ zellij binary not found in archive" >&2
  exit 1
fi
install -m 0755 "$zellij_bin" /usr/local/bin/zellij

# ---- Claude Code ----
# ロックで死んだら一度掃除して再実行（よくある）
set +e
curl -fsSL https://claude.ai/install.sh | bash
status=$?
set -e
if [ $status -ne 0 ]; then
  echo "⚠️ Claude install failed once; trying cleanup + retry"
  rm -f /root/.claude/*.lock 2>/dev/null || true
  curl -fsSL https://claude.ai/install.sh | bash
fi

# ---- Codex CLI ----
# 公式: npm i -g @openai/codex :contentReference[oaicite:2]{index=2}
npm install -g @openai/codex

# ---- rclone config in tmpfs ----
grep -q 'export RCLONE_CONFIG=' /root/.bashrc 2>/dev/null || \
  echo 'export RCLONE_CONFIG=/dev/shm/rclone.conf' >> /root/.bashrc

# ---- Auto-attach zellij on SSH login ----
cat >> /root/.bashrc << 'ZELLIJ_BLOCK'

# auto-start zellij on SSH (replaces vast.ai default tmux)
if command -v zellij &>/dev/null && [[ -z "$ZELLIJ" ]] && [[ -n "$SSH_CONNECTION" ]]; then
  exec zellij attach -c ssh_zellij
fi
ZELLIJ_BLOCK

rm -f /root/.bootstrap_running
echo "✅ BOOTSTRAP DONE"
