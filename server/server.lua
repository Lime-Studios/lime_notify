local resourceName = GetCurrentResourceName()
if resourceName ~= "lime_notify" then
    print("^1[ERROR]^7 Resource must be named 'lime_notify' ")
    print("^1[ERROR]^7 Current name: '" .. resourceName .. "'")
    print("^1[ERROR]^7 Resource will now stop")
    return
end

--[[
    Server-side Notify export.

    Usage:
        exports['lime_notify']:Notify(source, title, message, notifyType, duration)
        exports['lime_notify']:Notify(source, title, message, notifyType, duration, style)

    Parameters:
        source      — player server ID, or -1 to broadcast to all players
        title       — notification title string
        message     — notification body string
        notifyType  — "success" | "error" | "warning" | "info" | "claimed"
        duration    — milliseconds (default 5000)
        style       — (optional) override the player's saved style for this one notification
                      "default" | "minimal" | "glass" | "toast" | "bold" | "retro"
]]
local function NotifyServer(source, title, message, notifyType, duration, style)
    if source == -1 then
        TriggerClientEvent('lime_notify:Notify', -1, title, message, notifyType, duration, style)
    else
        TriggerClientEvent('lime_notify:Notify', source, title, message, notifyType, duration, style)
    end
end

exports('Notify', NotifyServer)
