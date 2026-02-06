#!/usr/bin/env bash
set -e

REPO="https://github.com/kidotch/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

echo "=== dotfiles bootstrap ==="

# 1. Clone or update
if [ -d "$DOTFILES_DIR" ]; then
  echo "[1/4] Updating dotfiles..."
  git -C "$DOTFILES_DIR" pull
else
  echo "[1/4] Cloning dotfiles..."
  git clone "$REPO" "$DOTFILES_DIR"
fi

# 2. Create symlinks
echo "[2/4] Creating symlinks..."
cd "$DOTFILES_DIR"
chmod +x ./install.sh
./install.sh

# 3. Setup locale
echo "[3/4] Setting up locale..."
chmod +x ./scripts/setup-locale-tmux.sh
./scripts/setup-locale-tmux.sh

# 4. Export locale for current shell
echo "[4/4] Exporting locale..."
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

echo ""
echo "=== Done! ==="
echo "Run: tmux"
