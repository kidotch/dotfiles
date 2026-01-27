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

----------------------------------------------------
-- Font / Input
----------------------------------------------------
config.font_size = 12
config.use_ime = true
config.adjust_window_size_when_changing_font_size = false

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
    key = "o",
    mods = "CTRL",
    action = wezterm.action.EmitEvent("increase-opacity"),
  },
  {
    key = "o",
    mods = "CTRL|SHIFT",
    action = wezterm.action.EmitEvent("decrease-opacity"),
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
  {
    key = "0",
    mods = "CTRL",
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
}

----------------------------------------------------
-- Window / Appearance
----------------------------------------------------
config.window_background_opacity = 0.6
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 0.4,
}
config.color_scheme = 'Solarized Dark Higher Contrast'
-- config.color_scheme = 'Kanagawa Dragon (Gogh)'
-- config.color_scheme = 'AdventureTime'
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
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false
config.colors = {
  tab_bar = {
    inactive_tab_edge = "none",
  },
  compose_cursor = "#e06c75",  -- IME変換中のカーソル色
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

local function apply_transparency_mode(window)
  local overrides = window:get_config_overrides() or {}
  local mode = wezterm.GLOBAL.transparency_mode
  local is_opaque = mode == 2

  overrides.win32_system_backdrop = mode == 0 and "Acrylic" or nil
  overrides.window_background_opacity = is_opaque and 1.0 or (wezterm.GLOBAL.opacity or 0.6)

  if is_opaque then
    local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
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
    overrides.window_background_gradient = { colors = { "#000000" } }
    overrides.colors = {
      foreground = "#ffffff",
      tab_bar = {
        background = "transparent",
        inactive_tab_edge = "none",
        active_tab = {
          bg_color = "transparent",
          fg_color = "#ffffff",
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

wezterm.on("update-right-status", function(window, pane)
  apply_transparency_mode(window)
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

return config
