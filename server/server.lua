--[[
    lime_notify — server core
]]

local resourceName = GetCurrentResourceName()
if resourceName ~= 'lime_notify' then
    print('^1[lime_notify] ERROR:^7 Resource must be named \'lime_notify\'')
    print('^1[lime_notify] ERROR:^7 Current name: \'' .. resourceName .. '\'')
    print('^1[lime_notify] ERROR:^7 Resource will now stop.')
    return
end

--[[
    Server-side Notify export.

    exports['lime_notify']:Notify(source, title, message, type, duration, style)

    source   — player server ID, or -1 to broadcast to all players
    type     — 'success' | 'error' | 'warning' | 'info' | 'claimed'
    duration — ms (default 5000)
    style    — optional per-notification style override
]]
local function NotifyServer(source, title, message, notifyType, duration, style)
    TriggerClientEvent('lime_notify:Notify', source,
        title    or 'Notification',
        message  or '',
        notifyType or 'info',
        duration   or 5000,
        style
    )
end

exports('Notify', NotifyServer)
