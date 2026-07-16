local resourceName = GetCurrentResourceName()
if resourceName ~= 'lime_notify' then
    print('^1[lime_notify] ERROR:^7 Resource must be named \'lime_notify\' (current: \'' .. resourceName .. '\')')
    return
end

--[[
    exports['lime_notify']:Notify(source, title, message, type, duration, style)
        source = -1 broadcasts to all players. duration = 0 → sticky.

    exports['lime_notify']:Progress(source, title, message, duration, type, style)
        Progress-bar notification that fills over the duration.
]]

local function NotifyServer(source, title, message, notifyType, duration, style)
    TriggerClientEvent('lime_notify:Notify', source,
        title or 'Notification', message or '',
        notifyType or 'info', duration or 5000, style)
end

local function ProgressServer(source, title, message, duration, notifyType, style)
    TriggerClientEvent('lime_notify:Progress', source,
        title or 'Working…', message or '',
        duration or 5000, notifyType or 'info', style)
end

exports('Notify',   NotifyServer)
exports('Progress', ProgressServer)
