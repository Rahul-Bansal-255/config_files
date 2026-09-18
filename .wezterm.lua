local wezterm = require 'wezterm'
local act = wezterm.action


local config = {
    font_size = 14.0,
    enable_tab_bar = false,
    default_prog = { "bash" },
}


wezterm.on("gui-startup", function(cmd)
  local tab1, pane1, window = wezterm.mux.spawn_window({ args = { "bash" } })

  local tab2, pane2, _ = window:spawn_tab({ args = { "bash" } })

  pane1:activate()
  window:gui_window():maximize()
end)


wezterm.on("toggle-tabbar", function(window, _)
    local overrides = window:get_config_overrides() or {}
    if overrides.enable_tab_bar == false then
        wezterm.log_info("tab bar shown")
        overrides.enable_tab_bar = true
    else
        wezterm.log_info("tab bar hidden")
        overrides.enable_tab_bar = false
    end
    window:set_config_overrides(overrides)
end)


config.keys = {
    { key = "F11" ,                  action = wezterm.action.ToggleFullScreen },
    { key = "T"   ,  mods = "CTRL",  action = act.EmitEvent("toggle-tabbar") },
}


return config

