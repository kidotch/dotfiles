#!/bin/bash
set -euo pipefail

# ==============================================================================
# vast.ai bootstrap with real-time progress tracking
#
# Progress file : /root/.bootstrap_progress  (machine-readable JSON-ish)
# Human log     : /root/.bootstrap.log       (detailed output)
# SSH wait gate : /root/.bootstrap_running    (removed on completion)
#
# SSH into the instance at any time to see live progress.
# ==============================================================================

PROGRESS_FILE="/root/.bootstrap_progress"
LOG_FILE="/root/.bootstrap.log"
TOTAL_STEPS=11

# ---- progress helpers --------------------------------------------------------

progress_init() {
  cat > "$PROGRESS_FILE" <<EOF
TOTAL=$TOTAL_STEPS
CURRENT=0
STATUS=starting
STEP_NAME=initializing
STARTED=$(date +%s)
EOF
  : > "$LOG_FILE"
  log "🚀 BOOTSTRAP START ($(date '+%Y-%m-%d %H:%M:%S %Z'))"
}

progress_step() {
  local step_num="$1"
  local step_name="$2"
  cat > "$PROGRESS_FILE" <<EOF
TOTAL=$TOTAL_STEPS
CURRENT=$step_num
STATUS=running
STEP_NAME=$step_name
STARTED=$(grep '^STARTED=' "$PROGRESS_FILE" | cut -d= -f2)
STEP_STARTED=$(date +%s)
EOF
  log ""
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "[$step_num/$TOTAL_STEPS] $step_name"
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

progress_done() {
  local elapsed=$(( $(date +%s) - $(grep '^STARTED=' "$PROGRESS_FILE" | cut -d= -f2) ))
  local mins=$(( elapsed / 60 ))
  local secs=$(( elapsed % 60 ))
  cat > "$PROGRESS_FILE" <<EOF
TOTAL=$TOTAL_STEPS
CURRENT=$TOTAL_STEPS
STATUS=done
STEP_NAME=complete
ELAPSED=${mins}m${secs}s
EOF
  log ""
  log "✅ BOOTSTRAP DONE in ${mins}m${secs}s"
}

progress_fail() {
  local step_num="${1:-?}"
  local step_name="${2:-unknown}"
  cat > "$PROGRESS_FILE" <<EOF
TOTAL=$TOTAL_STEPS
CURRENT=$step_num
STATUS=failed
STEP_NAME=$step_name
FAILED_AT=$(date +%s)
EOF
  log "❌ BOOTSTRAP FAILED at step $step_num: $step_name"
}

log() {
  echo "$*" | tee -a "$LOG_FILE"
}

# trap to mark failure on unexpected exit
trap_handler() {
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    # read current step info
    local cur_step cur_name
    cur_step=$(grep '^CURRENT=' "$PROGRESS_FILE" 2>/dev/null | cut -d= -f2 || echo "?")
    cur_name=$(grep '^STEP_NAME=' "$PROGRESS_FILE" 2>/dev/null | cut -d= -f2 || echo "unknown")
    progress_fail "$cur_step" "$cur_name"
  fi
  rm -f /root/.bootstrap_running
}
trap trap_handler EXIT

# ---- initialize --------------------------------------------------------------

progress_init

# ---- vast.ai: disable auto tmux, use zellij instead ----
touch /root/.no_auto_tmux
sed -i 's/tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux; exit/true/g' /root/.bashrc 2>/dev/null || true

# ---- Bootstrap wait gate: SSH login waits until bootstrap finishes -----------
touch /root/.bootstrap_running
cat >> /root/.bashrc << 'WAIT_BLOCK'

# wait for bootstrap to finish — show live progress
if [ -f /root/.bootstrap_running ]; then
  echo ""
  echo "⏳ Bootstrap is running... watching progress"
  echo "   (log: tail -f /root/.bootstrap.log)"
  echo ""
  while [ -f /root/.bootstrap_running ]; do
    if [ -f /root/.bootstrap_progress ]; then
      eval "$(cat /root/.bootstrap_progress)"
      local_elapsed=""
      if [ -n "${STARTED:-}" ]; then
        local_elapsed=$(( $(date +%s) - STARTED ))
        local_elapsed="$(( local_elapsed / 60 ))m$(( local_elapsed % 60 ))s"
      fi
      # progress bar
      if [ "${TOTAL:-0}" -gt 0 ] && [ "${CURRENT:-0}" -gt 0 ]; then
        pct=$(( CURRENT * 100 / TOTAL ))
        filled=$(( CURRENT * 20 / TOTAL ))
        empty=$(( 20 - filled ))
        bar=$(printf '%0.s█' $(seq 1 $filled 2>/dev/null) 2>/dev/null || true)
        bar_empty=$(printf '%0.s░' $(seq 1 $empty 2>/dev/null) 2>/dev/null || true)
        printf "\r  [%s%s] %3d%% (%d/%d) %s  [%s]  " \
          "$bar" "$bar_empty" "$pct" "${CURRENT}" "${TOTAL}" "${STEP_NAME:-...}" "${local_elapsed}"
      else
        printf "\r  ⏳ Initializing...  "
      fi
    fi
    sleep 1
  done
  echo ""
  if [ -f /root/.bootstrap_progress ]; then
    eval "$(cat /root/.bootstrap_progress)"
    if [ "${STATUS:-}" = "done" ]; then
      echo "✅ Bootstrap complete! (${ELAPSED:-})"
    else
      echo "⚠️  Bootstrap finished with status: ${STATUS:-unknown}"
      echo "    Check /root/.bootstrap.log for details"
    fi
  fi
  echo ""
  if [[ -x /usr/local/bin/zellij ]] && [[ -z "${ZELLIJ:-}" ]] && [[ -n "${SSH_CONNECTION:-}" ]]; then
    exec /usr/local/bin/zellij attach -c ssh_zellij
  fi
fi
WAIT_BLOCK

export DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# STEP 1: apt-get update & install base packages
# ==============================================================================
progress_step 1 "apt-get update & base packages"
apt-get update -y >> "$LOG_FILE" 2>&1
apt-get install -y --no-install-recommends \
  ca-certificates curl git build-essential unzip tmux \
  gnupg dirmngr xz-utils rclone vim tzdata >> "$LOG_FILE" 2>&1
update-ca-certificates >> "$LOG_FILE" 2>&1 || true
log "  ✓ base packages installed"

# ==============================================================================
# STEP 2: Node.js (NodeSource)
# ==============================================================================
progress_step 2 "Node.js (v22 via NodeSource)"
curl -fsSL https://deb.nodesource.com/setup_22.x 2>>"$LOG_FILE" | bash - >> "$LOG_FILE" 2>&1
apt-get install -y nodejs >> "$LOG_FILE" 2>&1
log "  ✓ node $(node --version), npm $(npm --version)"

# ==============================================================================
# STEP 3: npm global prefix
# ==============================================================================
progress_step 3 "npm global prefix"
mkdir -p /root/.npm-global
npm config set prefix /root/.npm-global
export PATH="/root/.npm-global/bin:$PATH"
grep -q 'export PATH="/root/.npm-global/bin:$PATH"' /root/.bashrc 2>/dev/null || \
  echo 'export PATH="/root/.npm-global/bin:$PATH"' >> /root/.bashrc
log "  ✓ npm prefix → /root/.npm-global"

# ==============================================================================
# STEP 4: Zellij
# ==============================================================================
progress_step 4 "Zellij (terminal multiplexer)"
tmpdir="$(mktemp -d)"
cd "$tmpdir"
curl -fL \
  https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz \
  -o zellij.tar.gz >> "$LOG_FILE" 2>&1
tar -xzf zellij.tar.gz
zellij_bin="$(find . -maxdepth 2 -type f -name zellij | head -n 1)"
if [ -z "${zellij_bin:-}" ]; then
  log "  ❌ zellij binary not found in archive"
  exit 1
fi
install -m 0755 "$zellij_bin" /usr/local/bin/zellij
log "  ✓ zellij installed → $(zellij --version 2>/dev/null || echo 'ok')"

# ==============================================================================
# STEP 5: glow (Markdown renderer)
# ==============================================================================
progress_step 5 "glow (Markdown renderer)"
GLOW_VERSION="${GLOW_VERSION:-2.0.0}"
cd "$tmpdir"
curl -fL \
  "https://github.com/charmbracelet/glow/releases/download/v${GLOW_VERSION}/glow_${GLOW_VERSION}_Linux_x86_64.tar.gz" \
  -o glow.tar.gz >> "$LOG_FILE" 2>&1
tar -xzf glow.tar.gz
glow_bin="$(find . -maxdepth 3 -type f -name glow | head -n 1)"
if [ -z "${glow_bin:-}" ]; then
  log "  ❌ glow binary not found in archive"
  exit 1
fi
install -m 0755 "$glow_bin" /usr/local/bin/glow
log "  ✓ glow v${GLOW_VERSION} installed"
rm -rf "$tmpdir"

# ==============================================================================
# STEP 6: Claude Code
# ==============================================================================
progress_step 6 "Claude Code"
set +e
curl -fsSL https://claude.ai/install.sh 2>>"$LOG_FILE" | bash >> "$LOG_FILE" 2>&1
status=$?
set -e
if [ $status -ne 0 ]; then
  log "  ⚠️ Claude install failed once; cleanup + retry"
  rm -f /root/.claude/*.lock 2>/dev/null || true
  curl -fsSL https://claude.ai/install.sh 2>>"$LOG_FILE" | bash >> "$LOG_FILE" 2>&1
fi
grep -q 'export PATH="$HOME/.local/bin:$PATH"' /root/.bashrc 2>/dev/null || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.bashrc
export PATH="$HOME/.local/bin:$PATH"
log "  ✓ claude installed → $(command -v claude || echo 'path pending')"

# ==============================================================================
# STEP 7: Codex CLI
# ==============================================================================
progress_step 7 "Codex CLI (npm)"
npm install -g @openai/codex >> "$LOG_FILE" 2>&1
log "  ✓ codex installed"

# ==============================================================================
# STEP 8: rclone config
# ==============================================================================
progress_step 8 "rclone config"
if [[ -n "${RCLONE_CONFIG_B64:-}" ]]; then
  echo "$RCLONE_CONFIG_B64" | base64 -d > /dev/shm/rclone.conf
  chmod 600 /dev/shm/rclone.conf
  unset RCLONE_CONFIG_B64
  log "  ✓ rclone config written to /dev/shm/rclone.conf"
else
  log "  ⏭ RCLONE_CONFIG_B64 not set, skipping"
fi
export RCLONE_CONFIG=/dev/shm/rclone.conf
grep -q 'export RCLONE_CONFIG=' /root/.bashrc 2>/dev/null || \
  echo 'export RCLONE_CONFIG=/dev/shm/rclone.conf' >> /root/.bashrc

# ==============================================================================
# STEP 9: Claude Code session sync (pull from GDrive)
# ==============================================================================
progress_step 9 "Claude session sync (GDrive pull)"
export RCLONE_CONFIG=/dev/shm/rclone.conf
GDRIVE_CLAUDE="${GDRIVE_CLAUDE:-gdrive:dotfiles/claude}"
if [[ -f /dev/shm/rclone.conf ]]; then
  rclone copy "${GDRIVE_CLAUDE}" /root/.claude \
    --exclude .credentials.json --exclude "*.lock" \
    >> "$LOG_FILE" 2>&1 \
    && log "  ✓ Claude sessions restored" \
    || log "  ⚠️ Claude session sync failed (first run?)"
else
  log "  ⏭ no rclone config, skipping GDrive sync"
fi

# ==============================================================================
# STEP 10: claude-sync helper
# ==============================================================================
progress_step 10 "claude-sync helper script"
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
log "  ✓ claude-sync installed"

# ==============================================================================
# STEP 11: Shell config finalization
# ==============================================================================
progress_step 11 "shell config finalization"

# vim config
echo 'set encoding=utf-8' > /root/.vimrc

# auto-attach zellij on SSH login
cat >> /root/.bashrc << 'ZELLIJ_BLOCK'

# auto-start zellij on SSH (replaces vast.ai default tmux)
if command -v zellij &>/dev/null && [[ -z "${ZELLIJ:-}" ]] && [[ -n "${SSH_CONNECTION:-}" ]]; then
  exec zellij attach -c ssh_zellij
fi
ZELLIJ_BLOCK

log "  ✓ .vimrc, zellij auto-attach configured"

# ---- verification ------------------------------------------------------------
log ""
log "── Installed versions ──"
log "  node    : $(node --version 2>/dev/null || echo 'N/A')"
log "  npm     : $(npm --version 2>/dev/null || echo 'N/A')"
log "  zellij  : $(zellij --version 2>/dev/null || echo 'N/A')"
log "  glow    : $(glow --version 2>/dev/null || echo 'N/A')"
log "  claude  : $(command -v claude 2>/dev/null || echo 'N/A')"
log "  rclone  : $(rclone --version 2>/dev/null | head -1 || echo 'N/A')"

# ---- mark complete (trap will remove .bootstrap_running) ---------------------
progress_done
