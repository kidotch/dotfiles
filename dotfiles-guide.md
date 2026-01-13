# Dotfiles 運用ガイド

## 概要

dotfilesリポジトリで設定ファイルを一元管理し、複数のPCで同期する方法。

- リポジトリ: https://github.com/ahchan-d/dotfiles.git
- 管理対象:
  - `wezterm/` - WezTerm設定
  - `nvim/` - Neovim設定

---

## 設定ファイル更新時

設定ファイルを編集した後、以下を実行：

```bash
cd ~/dotfiles
git add .
git commit -m "Update wezterm config"  # 変更内容に合わせてメッセージを変更
git push
```

---

## 他のPCでのセットアップ

### 1. リポジトリのクローン

```bash
cd ~
git clone https://github.com/ahchan-d/dotfiles.git
```

### 2. シンボリックリンクの作成

#### Windows (Git Bash / MSYS2)

```bash
# 既存の設定があればバックアップ
mv ~/.config/wezterm ~/.config/wezterm.bak
mv ~/AppData/Local/nvim ~/AppData/Local/nvim.bak

# シンボリックリンク作成
ln -s ~/dotfiles/wezterm ~/.config/wezterm
ln -s ~/dotfiles/nvim ~/AppData/Local/nvim
```

#### Windows (PowerShell 管理者権限)

```powershell
# 既存の設定があればバックアップ
Move-Item "$env:USERPROFILE\.config\wezterm" "$env:USERPROFILE\.config\wezterm.bak"
Move-Item "$env:USERPROFILE\AppData\Local\nvim" "$env:USERPROFILE\AppData\Local\nvim.bak"

# シンボリックリンク作成
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.config\wezterm" -Target "$env:USERPROFILE\dotfiles\wezterm"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\AppData\Local\nvim" -Target "$env:USERPROFILE\dotfiles\nvim"
```

### 3. 最新の変更を取得

既にクローン済みの場合：

```bash
cd ~/dotfiles

git checkout .

git pull
```

---

## 便利なエイリアス（任意）

`.bashrc`や`.zshrc`に追加：

```bash
alias dotfiles='cd ~/dotfiles && git status'
alias dotsync='cd ~/dotfiles && git add . && git commit -m "Update dotfiles" && git push'
```

---

## ディレクトリ構成

```
~/dotfiles/
├── .git/
├── .gitignore
├── wezterm/
│   └── wezterm.lua
└── nvim/
    ├── init.lua
    ├── lazy-lock.json
    └── lua/
```

## シンボリックリンク構成

| 元の場所 | リンク先 |
|----------|----------|
| `~/.config/wezterm` | `~/dotfiles/wezterm` |
| `~/AppData/Local/nvim` | `~/dotfiles/nvim` |
