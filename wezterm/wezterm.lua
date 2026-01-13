local wezterm = require 'wezterm'
local config = {}

----------------------------------------------------
-- Core
----------------------------------------------------
config.automatically_reload_config = true
config.enable_kitty_keyboard = false
config.status_update_interval = 500
config.term = "xterm-256color"

----------------------------------------------------
-- Font / Input
----------------------------------------------------
config.font_size = 14
config.use_ime = true

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
    key = "a",
    mods = "CTRL|SHIFT",
    action = wezterm.action.EmitEvent("toggle-acrylic"),
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
  -- ペイン切り替え
  {
    key = "n",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivatePaneDirection("Next"),
  },
  {
    key = "p",
    mods = "CTRL|SHIFT",
    action = wezterm.action.ActivatePaneDirection("Prev"),
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
  saturation = 0.8,
  brightness = 0.6,
}
config.color_scheme = 'Dracula+'

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
config.window_background_gradient = {
  colors = { "#000000" },
}
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false
config.colors = {
  tab_bar = {
    inactive_tab_edge = "none",
  },
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
-- Acrylic (Active only)
----------------------------------------------------
wezterm.GLOBAL.acrylic_enabled = wezterm.GLOBAL.acrylic_enabled ~= false

local function apply_backdrop_for_focus(window)
  local overrides = window:get_config_overrides() or {}
  if window:is_focused() and wezterm.GLOBAL.acrylic_enabled then
    overrides.win32_system_backdrop = "Acrylic"
  else
    overrides.win32_system_backdrop = nil --"Acrylic"
  end
  window:set_config_overrides(overrides)
end

wezterm.on("window-focus-changed", function(window, pane)
  if window:is_focused() then
    wezterm.GLOBAL.acrylic_enabled = true
  end
  apply_backdrop_for_focus(window)
end)

wezterm.on("update-right-status", function(window, pane)
  apply_backdrop_for_focus(window)
  window:invalidate()
end)

wezterm.on("toggle-acrylic", function(window, pane)
  wezterm.GLOBAL.acrylic_enabled = not wezterm.GLOBAL.acrylic_enabled
  apply_backdrop_for_focus(window)
end)

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

local function apply_opacity(window)
  local overrides = window:get_config_overrides() or {}
  overrides.window_background_opacity = wezterm.GLOBAL.opacity
  window:set_config_overrides(overrides)
end

wezterm.on("increase-opacity", function(window, pane)
  wezterm.GLOBAL.opacity = math.min(1.0, wezterm.GLOBAL.opacity + 0.1)
  apply_opacity(window)
end)

wezterm.on("decrease-opacity", function(window, pane)
  wezterm.GLOBAL.opacity = math.max(0.1, wezterm.GLOBAL.opacity - 0.1)
  apply_opacity(window)
end)

return config
