# Keymaps

This file documents the key mappings defined in `keymaps.lua`.

## Global

- `<leader>ub`: Toggle background transparency.
- `<F12>`: Map to `<Esc>` in normal/insert/visual/select modes.
- `<M-h>`: Decrease window width by 2.
- `<M-l>`: Increase window width by 2.
- `<Tab>` (insert): Accept Copilot suggestion if visible, otherwise insert a tab.

## NvimTree

- `<leader>tt`: Toggle tree.
- `<leader>tF`: Focus tree.
- `<leader>tf`: Find current file in tree.
- `<leader>tr`: Refresh tree.
- `<leader>tc`: Collapse tree.
- `<leader>to`: Open tree.
- `<leader>tq`: Close tree.

## CSV (FileType=csv)

- `dc`: Delete current CSV cell.
- `rc`: Replace current CSV cell with OS clipboard content.
- `yc`: Yank current CSV cell.
- `dq`: Delete quoted range under cursor.
- `yq`: Yank quoted content under cursor.
- `rq`: Replace quoted content under cursor with OS clipboard content.
- `sc`: Quote current CSV cell (escape inner quotes).
