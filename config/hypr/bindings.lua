-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Screenshot (unbind Google Maps and bind to interactive screenshot capture).
-- Clicking a window gives a macOS-style shot (transparent rounded corners,
-- hairline, shadow); a dragged region is saved as is.
-- Avoid Alt+Shift combos here: they switch the us/ru layout, so the key no
-- longer matches.
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot", "~/.local/bin/screenshot-window-mac")
o.bind("SUPER + CTRL + SHIFT + S", "Window screenshot (macOS style)", "~/.local/bin/screenshot-window-mac windows")
o.bind("SHIFT + PRINT", "Active window screenshot (macOS style)", "~/.local/bin/screenshot-window-mac active")

-- Screen recording (stop if active, or open capture menu if idle)
o.bind("SUPER + SHIFT + R", "Screenrecording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")

-- Applications
o.bind("SUPER + H", "Happ", { launch = "happ", focus = "happ" })

hl.unbind("SUPER + C")
o.bind("SUPER + C", "VS Code", { launch = "code" })

hl.unbind("SUPER + T")
o.bind("SUPER + T", "Telegram", { launch = "Telegram" })

-- Window management
hl.unbind("SUPER + V")
o.bind("SUPER + V", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
