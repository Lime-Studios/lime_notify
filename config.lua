Config = {}

--[[
    NOTIFICATION POSITION
    ---------------------
    Choose one of the following options:

    "top-left"       "top-center"       "top-right"
    "middle-left"    "middle-center"    "middle-right"
    "bottom-left"    "bottom-center"    "bottom-right"
]]
Config.Position = "top-right"

--[[
    NOTIFICATION STYLE
    ------------------
    The default style applied when the server starts.
    Players can change this in-game with /editnotify.

    Available styles:

    "default"  — Dark card with coloured left border and icon box (original look)
    "minimal"  — Clean pill shape, no icon box, subtle text-only feel
    "glass"    — Frosted glass blur effect with soft glow
    "toast"    — Wide bottom-anchored bar, full-width feel
    "bold"     — Solid filled background using the notification colour
    "retro"    — Terminal / monospace pixel aesthetic
]]
Config.Style = "default"

--[[
    ALLOW PLAYER STYLE CHANGES
    --------------------------
    If true, players can pick their own style via /editnotify and it
    will be saved to their client KVP storage.
    If false, Config.Style above is always used and the style picker
    is hidden in the editor.
]]
Config.AllowPlayerStyle = true
