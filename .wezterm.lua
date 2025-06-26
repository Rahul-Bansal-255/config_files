local wezterm = require 'wezterm'
local act = wezterm.action


local config = {
  font_size = 12.0,
  enable_tab_bar = false,
}


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

