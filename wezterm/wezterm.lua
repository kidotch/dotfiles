local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local mux = wezterm.mux
local act = wezterm.action

-- IME オフ
local userprofile = os.getenv("USERPROFILE")
local zenhan = userprofile .. "\\bin\\zenhan\\bin64\\zenhan.exe"
local function ime_off()
  wezterm.background_child_process({ zenhan, "0" })
end

wezterm.on("ime-off", function(window, pane)
  ime_off()
end)

-- position and size
wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  
  local gui_window = window:gui_window()
  local screen = wezterm.gui.screens().active

  local width = 1920
  local height = 1080

  local x = (screen.width - width) / 2
  local y = (screen.height - height) / 2 - 40

  gui_window:set_position(x, y)
  gui_window:set_inner_size(width, height)
end)

----------------------------------------------------
-- Core
----------------------------------------------------
config.automatically_reload_config = true
config.enable_kitty_keyboard = false
config.status_update_interval = 1000
config.term = "xterm-256color"
config.default_prog = { "pwsh.exe" }
config.hide_mouse_cursor_when_typing = true
config.selection_word_boundary = " \t\n{}[]()\"'`<>;:,.|&=/"

config.quick_select_patterns = {
  -- クオート内の文字列
  "\"[^\"]+\"",
  "'[^']+'",
  "`[^`]+`",
  -- プログラミング的な単語（英数字、ハイフン、アンダースコア、ドット、スラッシュ、コロン）
  "[\\w./:~@#-]+",
}

----------------------------------------------------
-- Font / Input
----------------------------------------------------
config.font = wezterm.font("UDEV Gothic 35NF")
config.font_size = 14
config.use_ime = true
config.adjust_window_size_when_changing_font_size = false

----------------------------------------------------
-- Snippets (Ctrl+: で一覧表示)
-- snippets.txt に --- 区切りで管理
----------------------------------------------------
local snippets_file = wezterm.config_dir .. "/snippets.txt"

local function load_snippets_from_file()
  local f = io.open(snippets_file, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local result = {}
  local block = {}
  for line in content:gmatch("([^\n]*)\n?") do
    if line == "---" then
      if #block > 0 then
        while #block > 0 and block[#block] == "" do table.remove(block) end
        table.insert(result, { cmd = table.concat(block, "\n") })
        block = {}
      end
    else
      if line ~= "" or #block > 0 then
        table.insert(block, line)
      end
    end
  end
  -- 末尾に --- がなくても最後のブロックを読み込む（後方互換）
  if #block > 0 then
    while #block > 0 and block[#block] == "" do table.remove(block) end
    table.insert(result, { cmd = table.concat(block, "\n") })
  end
  return result
end

local function save_snippet_to_file(cmd)
  local f = io.open(snippets_file, "a")
  if not f then return end
  f:write(cmd .. "\n---\n")
  f:close()
end

-- Snippet label colors
local C = {
  cmd   = "\x1b[38;2;86;182;194m",   -- cyan (コマンド)
  add   = "\x1b[38;2;152;195;121m",   -- green (追加ボタン)
  key   = "\x1b[38;2;229;192;123m",   -- yellow (キーバインド)
  desc  = "\x1b[38;2;171;178;191m",   -- gray (説明)
  reset = "\x1b[0m",
}

local function build_snippet_choices()
  local choices = {}
  for _, s in ipairs(load_snippets_from_file()) do
    local display = s.cmd:gsub("\n", "↵")
    local label = C.cmd .. display .. C.reset
    table.insert(choices, { label = label, id = s.cmd })
  end

  table.insert(choices, { label = C.add .. "+ Add new snippet" .. C.reset, id = "__add__" })
  return choices
end

----------------------------------------------------
-- Keybind Help
----------------------------------------------------
local keybind_list = {
  -- カスタム
  { key = "--- カスタム ---",  desc = "" },
  { key = "Ctrl+Shift+Enter", desc = "ペイン分割 (自動方向)" },
  { key = "Ctrl+Shift+Q",     desc = "ペインを閉じる" },
  { key = "Ctrl+Shift+B",     desc = "透過モード切替" },
  { key = "Ctrl+Shift+Alt+↑", desc = "透明度を上げる" },
  { key = "Ctrl+Shift+Alt+↓", desc = "透明度を下げる" },
  { key = "Ctrl+Shift+R",     desc = "ペインをローテーション" },
  { key = "Ctrl+Shift+S",     desc = "ペインをスワップ" },
  { key = "Ctrl+Shift+N",     desc = "次のペインへ移動" },
  { key = "Ctrl+Shift+P",     desc = "前のペインへ移動" },
  { key = "Ctrl+Shift+Arrow", desc = "方向指定でペイン移動" },
  { key = "Ctrl+V",           desc = "貼り付け" },
  { key = "Ctrl+Shift+C",     desc = "コピーモード (行選択)" },
  { key = "Ctrl+Shift+0",     desc = "フォントサイズリセット" },
  { key = "Ctrl+Tab",         desc = "次のタブへ" },
  { key = "Ctrl+Shift+Tab",   desc = "前のタブへ" },
  { key = "Ctrl+:",           desc = "スニペット一覧" },
  { key = "Ctrl+Shift+K",     desc = "キーバインド一覧 (このヘルプ)" },
  { key = "y (選択中)",       desc = "選択テキストをコピー" },
  { key = "Ctrl+Shift+U/D",   desc = "コピーモード PageUp/Down" },
  { key = "Ctrl+Shift+Space", desc = "QuickSelect (単語コピー)" },
  { key = "Ctrl+Shift+A",      desc = "テーマ切替 (light/dark)" },
  { key = "PageUp/Down",      desc = "スクロール (25%)" },
  { key = "Home/End",         desc = "先頭/末尾へスクロール" },
  { key = "F11",              desc = "フルスクリーン" },
  -- デフォルト
  { key = "--- デフォルト ---", desc = "" },
  { key = "Ctrl+Shift+W",     desc = "タブを閉じる" },
  { key = "Ctrl+Shift+1~9",   desc = "タブを番号で切替" },

  { key = "Ctrl+Shift+F",     desc = "検索" },
  { key = "Ctrl+Shift+X",     desc = "コピーモード" },
  { key = "Ctrl+Shift+Space", desc = "クイック選択モード" },
  { key = "Ctrl+Shift+U",     desc = "Unicode 文字選択" },
  { key = "Ctrl+Shift+L",     desc = "デバッグオーバーレイ" },
  { key = "Ctrl+=",           desc = "フォントサイズ拡大" },
  { key = "Ctrl+-",           desc = "フォントサイズ縮小" },
}

local function build_keybind_choices()
  local choices = {}
  for _, kb in ipairs(keybind_list) do
    if kb.desc == "" then
      -- セクション見出し
      local label = C.add .. kb.key .. C.reset
      table.insert(choices, { label = label, id = "__header__" })
    else
      local pad_len = math.max(1, 22 - #kb.key)
      local pad = string.rep(" ", pad_len)
      local label = C.key .. kb.key .. pad .. C.desc .. kb.desc .. C.reset
      table.insert(choices, { label = label, id = kb.key })
    end
  end
  return choices
end

----------------------------------------------------
-- Keybinds
----------------------------------------------------
config.keys = {
  {
    key = "q",
    mods = "CTRL|SHIFT",
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  {
    key = "b",
    mods = "CTRL|SHIFT",
    action = wezterm.action.EmitEvent("toggle-transparency-mode"),
  },
  {
    key = "DownArrow",
    mods = "CTRL|SHIFT|ALT",
    action = wezterm.action.EmitEvent("increase-opacity"),
  },
  {
    key = "UpArrow",
    mods = "CTRL|SHIFT|ALT",
    action = wezterm.action.EmitEvent("decrease-opacity"),
  },
  -- ペイン分割（横↔縦を自動交互）
  {
    key = "Enter",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      local tab = pane:tab()
      local panes = tab:panes_with_info()
      -- このペインの情報を取得
      local my_info
      for _, p in ipairs(panes) do
        if p.pane:pane_id() == pane:pane_id() then
          my_info = p
          break
        end
      end
      -- ペインが横長なら横分割(Bottom)、縦長なら縦分割(Right)
      if my_info then
        local w = my_info.pixel_width
        local h = my_info.pixel_height
        if w >= h then
          pane:split({ direction = "Right" })
        else
          pane:split({ direction = "Bottom" })
        end
      else
        pane:split({ direction = "Right" })
      end
    end),
  },
  -- ペイン入れ替え
  {
    key = "r",
    mods = "CTRL|SHIFT",
    action = wezterm.action.RotatePanes("Clockwise"),
  },
  {
    key = "s",
    mods = "CTRL|SHIFT",
    action = wezterm.action.PaneSelect({ mode = "SwapWithActive" }),
  },
  -- ペイン切り替え（IME オフ付き）
  {
    key = "n",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.ActivatePaneDirection("Next"),
      act.EmitEvent("ime-off"),
    }),
  },
  {
    key = "p",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.ActivatePaneDirection("Prev"),
      act.EmitEvent("ime-off"),
    }),
  },
  -- ペイン切り替え（IME オフ付き）: Ctrl+Shift+矢印
  {
    key = "LeftArrow",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.ActivatePaneDirection("Left"),
      act.EmitEvent("ime-off"),
    }),
  },
  {
    key = "RightArrow",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.ActivatePaneDirection("Right"),
      act.EmitEvent("ime-off"),
    }),
  },
  {
    key = "UpArrow",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.ActivatePaneDirection("Up"),
      act.EmitEvent("ime-off"),
    }),
  },
  {
    key = "DownArrow",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.ActivatePaneDirection("Down"),
      act.EmitEvent("ime-off"),
    }),
  },
  -- 貼り付け
  {
    key = "v",
    mods = "CTRL",
    action = act.PasteFrom("Clipboard"),
  },
  -- コピーモード + 行選択開始
  {
    key = "c",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.EmitEvent("ime-off"),
      act.EmitEvent("copy-mode-line-select"),
    }),
  },
  {
    key = "0",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ResetFontSize,
  },
  -- タブ切り替え（IME オフ付き）
  {
    key = "Tab",
    mods = "CTRL",
    action = act.Multiple({
      act.ActivateTabRelative(1),
      act.EmitEvent("ime-off"),
    }),
  },
  {
    key = "Tab",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.ActivateTabRelative(-1),
      act.EmitEvent("ime-off"),
    }),
  },
  --[[ 矢印キーでペイン移動
  {
    key = "LeftArrow",
    mods = "ALT",
    action = wezterm.action.ActivatePaneDirection("Left"),
  },
  {
    key = "RightArrow",
    mods = "ALT",
    action = wezterm.action.ActivatePaneDirection("Right"),
  },
  {
    key = "UpArrow",
    mods = "ALT",
    action = wezterm.action.ActivatePaneDirection("Up"),
  },
  {
    key = "DownArrow",
    mods = "ALT",
    action = wezterm.action.ActivatePaneDirection("Down"),
  }]]
  --[[,
  {
    key = "LeftArrow",
    mods = "CTRL|SHIFT",
    action = wezterm.action.MoveTabRelative(-1),
  },
  {
    key = "RightArrow",
    mods = "CTRL|SHIFT",
    action = wezterm.action.MoveTabRelative(1),
  },]]
  -- スニペット
  {
    key = ":",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(act.InputSelector({
        title = "Snippets",
        choices = build_snippet_choices(),
        action = wezterm.action_callback(function(window, pane, id, label)
          if not id then return end
          if id == "__add__" then
            window:perform_action(act.PromptInputLine({
              description = "Enter command to add:",
              action = wezterm.action_callback(function(window, pane, line)
                if line and line ~= "" then
                  save_snippet_to_file(line)
                end
              end),
            }), pane)
          else
            pane:send_text(id)
          end
        end),
      }), pane)
    end),
  },
  -- コピーモード（デフォルト上書き、IME OFF付き）
  {
    key = "x",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.EmitEvent("ime-off"),
      act.ActivateCopyMode,
    }),
  },
  -- QuickSelect（画面上の単語をヒントキーでコピー）
  {
    key = "g",
    mods = "CTRL|SHIFT",
    action = act.QuickSelectArgs({
      scope_lines = 0,
      action = wezterm.action_callback(function(window, pane)
        local text = window:get_selection_text_for_pane(pane)
        if text and text ~= "" then
          window:copy_to_clipboard(text, "Clipboard")
        end
      end),
    }),
  },
  -- フルスクリーン
  {
    key = "F11",
    action = act.ToggleFullScreen,
  },
  -- キーバインドヘルプ
  {
    key = "k",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(act.InputSelector({
        title = "Keybindings",
        choices = build_keybind_choices(),
        action = wezterm.action_callback(function(window, pane, id, label)
          -- 選択しても何もしない（閲覧用）
        end),
      }), pane)
    end),
  },
  -- マウス選択中に y でコピー（選択なしなら通常入力）
  {
    key = "y",
    mods = "NONE",
    action = wezterm.action_callback(function(window, pane)
      local sel = window:get_selection_text_for_pane(pane)
      if sel and sel ~= "" then
        window:perform_action(act.CopyTo("Clipboard"), pane)
        window:perform_action(act.ClearSelection, pane)
      else
        window:perform_action(act.SendKey({ key = "y" }), pane)
      end
    end),
  },
  -- スクロール（コピーモード、半ページ）
  {
    key = "u",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.EmitEvent("ime-off"),
      act.ActivateCopyMode,
      act.CopyMode("PageUp"),
    }),
  },
  {
    key = "d",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.EmitEvent("ime-off"),
      act.ActivateCopyMode,
      act.CopyMode("PageDown"),
    }),
  },
  -- テーマ切替（light ↔ dark）
  {
    key = "a",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      if wezterm.GLOBAL.color_mode == "light" then
        wezterm.GLOBAL.color_mode = "dark"
      else
        wezterm.GLOBAL.color_mode = "light"
      end
      write_theme_file(wezterm.GLOBAL.color_mode)
      apply_transparency_mode(window)
    end),
  },
  -- スクロール（通常）
  {
    key = "PageUp",
    action = act.ScrollByPage(-0.25),
  },
  {
    key = "PageDown",
    action = act.ScrollByPage(0.25),
  },
  {
    key = "Home",
    action = act.ScrollToTop,
  },
  {
    key = "End",
    action = act.ScrollToBottom,
  },
}

----------------------------------------------------
-- Window / Appearance
----------------------------------------------------
config.window_background_opacity = 0.6
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 0.4,
}
-- color_scheme is set dynamically by GLOBAL.color_mode (see Color Mode section above)
----------------------------------------------------
-- Tab
----------------------------------------------------
config.window_decorations = "RESIZE"
config.show_tabs_in_tab_bar = true
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
  font_size = 12,
}
-- window_background_gradient is managed dynamically in apply_transparency_mode()
config.use_fancy_tab_bar = true
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false
config.colors = {
  tab_bar = {
    inactive_tab_edge = "none",
  },
  compose_cursor = "#e06c75",  -- IME変換中のカーソル色
  quick_select_label_bg = { Color = "#e06c75" },
  quick_select_label_fg = { Color = "#ffffff" },
  quick_select_match_bg = { Color = "#3b4252" },
  quick_select_match_fg = { Color = "#88c0d0" },
}

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local title_text = tab.active_pane.title or ""
  local dash_split = title_text:match("^.*%s%-%s(.+)$")
  if dash_split and dash_split ~= "" then
    title_text = dash_split
  elseif title_text:match("[/\\]") then
    title_text = title_text:match("([^/\\]+)$") or title_text
  end

  local process = tab.active_pane.foreground_process_name or ""
  local process_name = process:match("([^/\\]+)$") or process
  process_name = process_name:gsub("%.exe$", "")
  if process_name ~= "" and process_name ~= "wslhost" then
    title_text = process_name
  end

  if title_text == "" then
    title_text = "unknown"
  end
  local title = "  " .. wezterm.truncate_right(title_text, max_width - 1) .. "  "
  return { { Text = title } }
end)

----------------------------------------------------
-- Transparency Mode (Ctrl+Shift+B to toggle)
-- Mode 0: Acrylic ON + Transparent
-- Mode 1: Acrylic OFF + Transparent
-- Mode 2: Opaque (no transparency)
----------------------------------------------------
wezterm.GLOBAL.transparency_mode = wezterm.GLOBAL.transparency_mode or 0

----------------------------------------------------
-- Color Mode (light / dark)
----------------------------------------------------
local theme_file = userprofile .. "\\.wezterm-theme"

local function read_theme_file()
  local f = io.open(theme_file, "r")
  if not f then return nil end
  local content = f:read("*l")
  f:close()
  if content then content = content:gsub("%s+", "") end
  return content
end

local function write_theme_file(mode)
  local f = io.open(theme_file, "w")
  if f then
    f:write(mode .. "\n")
    f:close()
  end
end

-- 初期化: ファイルがあればそこから復元、なければ現在の color_scheme から判定
if not wezterm.GLOBAL.color_mode then
  local saved = read_theme_file()
  if saved == "light" or saved == "dark" then
    wezterm.GLOBAL.color_mode = saved
  else
    wezterm.GLOBAL.color_mode = "light"
    write_theme_file("light")
  end
end

-- OneHalfLight の ansi Blue を暗めに調整したカスタムスキーム
local builtin = wezterm.color.get_builtin_schemes()
local light_custom = builtin["OneHalfLight"]
light_custom.ansi[5] = "#0056b3"  -- ansi[4] DarkBlue: #0184bc → 暗めの青（Lua 1-indexed）
light_custom.brights[3] = "#1a6b1a" -- brights[2] Green: #98c379 → 濃い緑（テーブルヘッダー等）

config.color_schemes = {
  ["OneHalfLight Custom"] = light_custom,
}

local color_schemes = {
  light = "OneHalfLight Custom",
  dark  = "Solarized Dark Higher Contrast",
}

config.color_scheme = color_schemes[wezterm.GLOBAL.color_mode]

local function is_light_theme()
  return wezterm.GLOBAL.color_mode == "light"
end

local function apply_transparency_mode(window)
  local overrides = window:get_config_overrides() or {}
  local mode = wezterm.GLOBAL.transparency_mode
  local is_opaque = mode == 2
  local light = is_light_theme()

  -- ライト/ダークに応じた透過時の色
  local fg = light and "#1a1b26" or "#ffffff"
  local bg_gradient = light and "#e1e2e7" or "#000000"

  overrides.color_scheme = color_schemes[wezterm.GLOBAL.color_mode]
  overrides.win32_system_backdrop = mode == 0 and "Acrylic" or nil
  overrides.window_background_opacity = is_opaque and 1.0 or (wezterm.GLOBAL.opacity or 0.6)

  if is_opaque then
    local scheme = wezterm.color.get_builtin_schemes()[color_schemes[wezterm.GLOBAL.color_mode]]
    overrides.window_background_gradient = { colors = { scheme.background } }
    overrides.colors = {
      tab_bar = {
        background = scheme.background,
        inactive_tab_edge = "none",
        active_tab = {
          bg_color = scheme.background,
          fg_color = scheme.foreground,
        },
      },
    }
  else
    overrides.window_background_gradient = { colors = { bg_gradient } }
    overrides.colors = {
      foreground = fg,
      tab_bar = {
        background = "transparent",
        inactive_tab_edge = "none",
        active_tab = {
          bg_color = "transparent",
          fg_color = fg,
        },
      },
    }
  end

  window:set_config_overrides(overrides)
end

wezterm.on("window-focus-changed", function(window, pane)
  apply_transparency_mode(window)
  if window:is_focused() then
    ime_off()
  end
end)

wezterm.GLOBAL.in_copy_mode = wezterm.GLOBAL.in_copy_mode or false

wezterm.on("update-right-status", function(window, pane)
  apply_transparency_mode(window)

  local key_table = window:active_key_table()
  if key_table == "copy_mode" and not wezterm.GLOBAL.in_copy_mode then
    wezterm.GLOBAL.in_copy_mode = true
    ime_off()
  elseif key_table ~= "copy_mode" then
    wezterm.GLOBAL.in_copy_mode = false
  end

  -- コピーモード表示
  local status = ""
  if key_table == "copy_mode" then
    status = wezterm.format({
      { Background = { Color = "#e06c75" } },
      { Foreground = { Color = "#282c34" } },
      { Text = "  COPY  " },
    })
  end
  window:set_right_status(status)
end)


wezterm.on("copy-mode-line-select", function(window, pane)
  window:perform_action(act.ActivateCopyMode, pane)
  window:perform_action(act.CopyMode({ SetSelectionMode = "Line" }), pane)
end)

wezterm.on("toggle-transparency-mode", function(window, pane)
  wezterm.GLOBAL.transparency_mode = (wezterm.GLOBAL.transparency_mode + 1) % 3
  apply_transparency_mode(window)
end)

--[[
----------------------------------------------------
-- Launch Menu
----------------------------------------------------
config.launch_menu = {
  { label = "PowerShell", program = "pwsh.exe" },
  { label = "Command Prompt", program = "cmd.exe" },
  { label = "WSL (Ubuntu)", program = "wsl.exe" },
}
]]

----------------------------------------------------
-- Window Layout
----------------------------------------------------
config.initial_cols = 120  -- 横幅（文字数）
config.initial_rows = 30 -- 縦幅（行数）

config.window_padding = {
  left = 5,
  right = 5,
  top = 5,
  bottom = 5,
}

wezterm.GLOBAL.opacity = wezterm.GLOBAL.opacity or 0.6

wezterm.on("increase-opacity", function(window, pane)
  wezterm.GLOBAL.opacity = math.min(1.0, wezterm.GLOBAL.opacity + 0.1)
  apply_transparency_mode(window)
end)

wezterm.on("decrease-opacity", function(window, pane)
  wezterm.GLOBAL.opacity = math.max(0.1, wezterm.GLOBAL.opacity - 0.1)
  apply_transparency_mode(window)
end)

----------------------------------------------------
-- Copy Mode キーテーブル拡張
----------------------------------------------------
local copy_mode = wezterm.gui.default_key_tables().copy_mode

-- デフォルトの w, y, u, d をカスタムで上書きするため除去
local override_keys = { y = true, u = true, d = true }
local filtered_copy_mode = {}
for _, k in ipairs(copy_mode) do
  if not (k.mods == "NONE" and override_keys[k.key]) then
    table.insert(filtered_copy_mode, k)
  end
end
copy_mode = filtered_copy_mode

local copy_mode_extra = {
  { key = "h", mods = "CTRL", action = act.CopyMode("MoveLeft") },
  { key = "j", mods = "CTRL", action = act.CopyMode("MoveDown") },
  { key = "k", mods = "CTRL", action = act.CopyMode("MoveUp") },
  { key = "l", mods = "CTRL", action = act.CopyMode("MoveRight") },
  -- 矩形選択
  { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
  -- コピーしてコピーモード終了
  { key = "y", mods = "NONE", action = act.Multiple({
    act.CopyTo("Clipboard"),
    act.CopyMode("Close"),
  })},
  -- ペースト（コピーモード終了 → 貼り付け）
  { key = "p", mods = "NONE", action = act.Multiple({
    act.CopyMode("Close"),
    act.PasteFrom("Clipboard"),
  })},
  -- スクロール（コピーモード中、半ページ）
  { key = "u", mods = "CTRL|SHIFT", action = act.CopyMode("PageUp") },
  { key = "d", mods = "CTRL|SHIFT", action = act.CopyMode("PageDown") },
  { key = "u", mods = "NONE", action = act.CopyMode("PageUp") },
  { key = "d", mods = "NONE", action = act.CopyMode("PageDown") },
}
for _, k in ipairs(copy_mode_extra) do
  table.insert(copy_mode, k)
end
local search_mode = {
  { key = "Escape", mods = "NONE", action = wezterm.action_callback(function(window, pane)
    window:perform_action(act.CopyMode("ClearPattern"), pane)
    window:perform_action(act.CopyMode("Close"), pane)
  end)},
  { key = "Enter", mods = "NONE", action = act.CopyMode("AcceptPattern") },
  { key = "Backspace", mods = "NONE", action = act.CopyMode("ClearPattern") },
}

config.key_tables = {
  copy_mode = copy_mode,
  search_mode = search_mode,
}

return config
