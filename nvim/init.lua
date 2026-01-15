-- 基本設定
vim.opt.number = true


vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("state") .. "/undo"
vim.opt.undolevels = 10000
vim.g.mapleader = " "


vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['+'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['+'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}
-- CSV/TSV filetype detection for rainbow_csv.nvim
vim.filetype.add({
  extension = {
    csv = "csv",
    tsv = "tsv",
  },
})

-- Terminal title for WezTerm tab name
vim.o.title = true
vim.o.titlestring = "Neovim"

-- lazy.nvim ブートストラップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- プラグイン読み込み
require("lazy").setup("plugins")

-- カラースキーム
vim.cmd.colorscheme("solarized-osaka")

-- 背景透過
local transparent_enabled = true

local function set_transparent()
  vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "NonText", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "MsgArea", { fg = "white" })
  vim.api.nvim_set_hl(0, "LineNr", { fg = "white" })
end

local function apply_transparency()
  if transparent_enabled then
    set_transparent()
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = apply_transparency,
})
vim.defer_fn(apply_transparency, 10)

vim.keymap.set("n", "<leader>tb", function()
  transparent_enabled = not transparent_enabled
  if transparent_enabled then
    apply_transparency()
  else
    vim.cmd.colorscheme("solarized-osaka")
  end
  vim.notify("Transparency: " .. (transparent_enabled and "on" or "off"))
end, { silent = true, desc = "Toggle transparency" })

-- F13 を Esc として使う
vim.keymap.set({ "n", "i", "v", "s" }, "<F13>", "<Esc>", { silent = true })
