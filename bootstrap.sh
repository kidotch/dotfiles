#!/bin/bash
set -euo pipefail

# ==============================================================================
# vast.ai bootstrap with real-time progress tracking
#
# /root/.bootstrap_step   — current step info (read by SSH wait gate)
# /root/.bootstrap.log    — detailed output log
# /root/.bootstrap_running — gate file (removed on completion)
# ==============================================================================

STEP_FILE="/root/.bootstrap_step"
LOG_FILE="/root/.bootstrap.log"
TOTAL=10

: > "$LOG_FILE"

step() {
  local n="$1" name="$2"
  echo "$n/$TOTAL $name" > "$STEP_FILE"
  echo "" >> "$LOG_FILE"
  echo "[$n/$TOTAL] $name" >> "$LOG_FILE"
  echo "[$n/$TOTAL] $name"
}

log() { echo "$*" | tee -a "$LOG_FILE"; }

# ---- vast.ai: disable auto tmux, use zellij instead ----
touch /root/.no_auto_tmux
sed -i 's/tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux; exit/true/g' /root/.bashrc 2>/dev/null || true

# ---- Bootstrap wait gate: SSH login waits until bootstrap finishes -----------
touch /root/.bootstrap_running
cat >> /root/.bashrc << 'WAIT_BLOCK'

# wait for bootstrap to finish — show live progress
if [ -f /root/.bootstrap_running ]; then
  echo ""
  echo "⏳ Bootstrap is running..."
  echo "   (detail: tail -f /root/.bootstrap.log)"
  echo ""
  while [ -f /root/.bootstrap_running ]; do
    if [ -f /root/.bootstrap_step ]; then
      step_info=$(cat /root/.bootstrap_step 2>/dev/null || true)
      cur=${step_info%%/*}
      rest=${step_info#*/}
      total=${rest%% *}
      name=${rest#* }
      if [ -n "$cur" ] && [ -n "$total" ] && [ "$total" -gt 0 ] 2>/dev/null; then
        filled=$(( cur * 20 / total ))
        bar=$(printf '%*s' "$filled" '' | tr ' ' '█')
        bar_empty=$(printf '%*s' "$(( 20 - filled ))" '' | tr ' ' '░')
        printf "\r  [%s%s] %s/%s %s   " "$bar" "$bar_empty" "$cur" "$total" "$name"
      fi
    fi
    sleep 1
  done
  printf "\r%60s\r" ""
  echo "✅ Bootstrap complete!"
  echo ""
  if [[ -x /usr/local/bin/zellij ]] && [[ -z "${ZELLIJ:-}" ]] && [[ -n "${SSH_CONNECTION:-}" ]]; then
    exec /usr/local/bin/zellij attach -c ssh_zellij
  fi
fi

# show bootstrap result inside zellij
if [ -n "${ZELLIJ:-}" ] && [ -f /root/.bootstrap_step ]; then
  echo "✅ Bootstrap done ($(cat /root/.bootstrap_step))"
fi
WAIT_BLOCK

export DEBIAN_FRONTEND=noninteractive

# === 1. Base packages ========================================================
step 1 "apt-get update & base packages"
apt-get update -y >> "$LOG_FILE" 2>&1
apt-get install -y --no-install-recommends \
  ca-certificates curl git build-essential unzip tmux \
  gnupg dirmngr xz-utils rclone vim tzdata >> "$LOG_FILE" 2>&1
update-ca-certificates >> "$LOG_FILE" 2>&1 || true

# === 2. Node.js ==============================================================
step 2 "Node.js (v22)"
curl -fsSL https://deb.nodesource.com/setup_22.x 2>>"$LOG_FILE" | bash - >> "$LOG_FILE" 2>&1
apt-get install -y nodejs >> "$LOG_FILE" 2>&1
log "  node $(node --version), npm $(npm --version)"

# npm global prefix
mkdir -p /root/.npm-global
npm config set prefix /root/.npm-global
export PATH="/root/.npm-global/bin:$PATH"
grep -q 'export PATH="/root/.npm-global/bin:$PATH"' /root/.bashrc 2>/dev/null || \
  echo 'export PATH="/root/.npm-global/bin:$PATH"' >> /root/.bashrc

# === 3. Zellij ================================================================
step 3 "Zellij"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"

curl -fL \
  https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz \
  -o zellij.tar.gz >> "$LOG_FILE" 2>&1
tar -xzf zellij.tar.gz
zellij_bin="$(find . -maxdepth 2 -type f -name zellij | head -n 1)"
if [ -z "${zellij_bin:-}" ]; then
  log "❌ zellij binary not found in archive"
  exit 1
fi
install -m 0755 "$zellij_bin" /usr/local/bin/zellij

# === 4. glow ==================================================================
step 4 "glow (Markdown renderer)"
GLOW_VERSION="${GLOW_VERSION:-2.0.0}"
cd "$tmpdir"
curl -fL \
  "https://github.com/charmbracelet/glow/releases/download/v${GLOW_VERSION}/glow_${GLOW_VERSION}_Linux_x86_64.tar.gz" \
  -o glow.tar.gz >> "$LOG_FILE" 2>&1
tar -xzf glow.tar.gz
glow_bin="$(find . -maxdepth 3 -type f -name glow | head -n 1)"
if [ -z "${glow_bin:-}" ]; then
  log "❌ glow binary not found in archive"
  exit 1
fi
install -m 0755 "$glow_bin" /usr/local/bin/glow
rm -rf "$tmpdir"

# === 5. Claude Code ===========================================================
step 5 "Claude Code"
set +e
curl -fsSL https://claude.ai/install.sh 2>>"$LOG_FILE" | bash >> "$LOG_FILE" 2>&1
status=$?
set -e
if [ $status -ne 0 ]; then
  log "  ⚠️ retry..."
  rm -f /root/.claude/*.lock 2>/dev/null || true
  curl -fsSL https://claude.ai/install.sh 2>>"$LOG_FILE" | bash >> "$LOG_FILE" 2>&1
fi
grep -q 'export PATH="$HOME/.local/bin:$PATH"' /root/.bashrc 2>/dev/null || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.bashrc
export PATH="$HOME/.local/bin:$PATH"

# === 6. Codex CLI =============================================================
step 6 "Codex CLI"
npm install -g @openai/codex >> "$LOG_FILE" 2>&1

# === 7. rclone config =========================================================
step 7 "rclone config"
if [[ -n "${RCLONE_CONFIG_B64:-}" ]]; then
  echo "$RCLONE_CONFIG_B64" | base64 -d > /dev/shm/rclone.conf
  chmod 600 /dev/shm/rclone.conf
  unset RCLONE_CONFIG_B64
  log "  rclone config → /dev/shm/rclone.conf"
fi
export RCLONE_CONFIG=/dev/shm/rclone.conf
grep -q 'export RCLONE_CONFIG=' /root/.bashrc 2>/dev/null || \
  echo 'export RCLONE_CONFIG=/dev/shm/rclone.conf' >> /root/.bashrc

# === 8. Claude session sync ===================================================
step 8 "Claude session sync (GDrive)"
export RCLONE_CONFIG=/dev/shm/rclone.conf
GDRIVE_CLAUDE="${GDRIVE_CLAUDE:-gdrive:dotfiles/claude}"
if [[ -f /dev/shm/rclone.conf ]]; then
  rclone copy "${GDRIVE_CLAUDE}" /root/.claude \
    --exclude .credentials.json --exclude "*.lock" \
    >> "$LOG_FILE" 2>&1 \
    && log "  ✓ sessions restored" \
    || log "  ⚠️ sync failed (first run?)"
else
  log "  skipped (no rclone config)"
fi

# === 9. claude-sync helper ====================================================
step 9 "claude-sync helper"
cat > /usr/local/bin/claude-sync << 'CLAUDE_SYNC'
#!/usr/bin/env bash
set -euo pipefail
GDRIVE_CLAUDE="${GDRIVE_CLAUDE:-gdrive:dotfiles/claude}"
EXCLUDE="--exclude .credentials.json --exclude *.lock"

case "${1:-}" in
  pull)
    echo "📥 Pulling Claude sessions from GDrive..."
    rclone copy "${GDRIVE_CLAUDE}" ~/.claude $EXCLUDE --progress
    echo "✅ done"
    ;;
  push)
    echo "📤 Pushing Claude sessions to GDrive..."
    rclone copy ~/.claude "${GDRIVE_CLAUDE}" $EXCLUDE --progress
    echo "✅ done"
    ;;
  *)
    echo "Usage: claude-sync [pull|push]"
    exit 2
    ;;
esac
CLAUDE_SYNC
chmod +x /usr/local/bin/claude-sync

# === 10. Shell config finalization ============================================
step 10 "shell config"
echo 'set encoding=utf-8' > /root/.vimrc

cat >> /root/.bashrc << 'ZELLIJ_BLOCK'

# auto-start zellij on SSH (replaces vast.ai default tmux)
if command -v zellij &>/dev/null && [[ -z "$ZELLIJ" ]] && [[ -n "$SSH_CONNECTION" ]]; then
  exec zellij attach -c ssh_zellij
fi
ZELLIJ_BLOCK

# ---- done --------------------------------------------------------------------
rm -f /root/.bootstrap_running
log ""
log "✅ BOOTSTRAP DONE"
