-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- Bigger windows: tighter gaps than Omarchy's 5/10.
hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 5,
  },
})

-- Glass: native compositor blur behind translucent surfaces.
-- https://wiki.hypr.land/Configuring/Basics/Variables/#blur
hl.config({
  decoration = {
    -- Rounded corners; the Omarchy shell reads this for its popups,
    -- notifications and menus too.
    rounding = 16,
    rounding_power = 2.5,

    blur = {
      enabled = true,
      size = 6,
      passes = 3,
      noise = 0.02,
      contrast = 0.9,
      brightness = 0.8,
      vibrancy = 0.2,
      vibrancy_darkness = 0.2,
      popups = true,
      new_optimizations = true,
      xray = false,
    },
  },
})

-- Blur behind shell surfaces; ignore_alpha keeps fully transparent pixels
-- (around text and outside cards) from being blurred.
-- omarchy-keyboard-panel is the full-screen layer behind the bar's dropdowns
-- (weather, F1, Wi-Fi, Bluetooth, audio...); only its card gets blurred.
hl.layer_rule({
  match = { namespace = "^(omarchy-bar|omarchy-keyboard-panel|omarchy-notifications|omarchy-osd|omarchy-menu|omarchy-clipboard|omarchy-emojis|omarchy-polkit|omarchy-reminders|omarchy-network-qr|fedor-f1-next)$" },
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.1,
})

-- Smooth motion: soft ease-out curves, a slight overshoot when windows open,
-- and sliding workspace switches (Omarchy ships with them off).
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("smoothOut", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("smoothInOut", { type = "bezier", points = { { 0.45, 0 }, { 0.15, 1 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.34, 1.25 }, { 0.64, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4.5, bezier = "smoothOut" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.5, bezier = "overshot", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.8, bezier = "smoothOut", style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4.5, bezier = "smoothOut" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "smoothOut" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.5, bezier = "smoothOut" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "smoothOut" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, bezier = "smoothOut", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.5, bezier = "smoothOut", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 3, bezier = "smoothOut" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.5, bezier = "smoothOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "smoothInOut", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.5, bezier = "smoothOut", style = "slidevert" })
