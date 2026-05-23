--[[
    lime_notify — compatibility hooks (SERVER)
    
    Catches server-side exports and events from popular notify scripts
    and routes them through lime_notify's own server export.
]]

local function resolveType(t)
    if t == 'inform' or t == 'primary' or t == 'phone' or t == 'phonemessage' or t == 'neutral' or t == 'alert' then
        return 'info'
    end
    return t or 'info'
end

local function notify(source, title, message, notifyType, duration)
    -- calls lime_notify's own server-side Notify export
    exports['lime_notify']:Notify(source, title, message, resolveType(notifyType), duration or 5000)
end

-- ================================================
-- motion_notify (server)
-- exports['motion_notify']:Notify(source, title, msg, type, duration)
-- ================================================
exports('Notify', function(source, title, message, notifyType, duration)
    notify(source, title, message, notifyType, duration)
end)

-- ================================================
-- okokNotify (server)
-- TriggerClientEvent('okokNotify:Alert', source, title, msg, duration, type)
-- ================================================
RegisterNetEvent('okokNotify:Alert', function(title, message, duration, notifyType)
    -- server fires this as a client event; caught here if triggered server-side
end)

-- Server export mirror
exports('Alert', function(source, title, message, duration, notifyType)
    notify(source, title, message, notifyType, duration)
end)

-- ================================================
-- mythic_notify (server)
-- TriggerClientEvent('mythic_notify:client:SendAlert', source, { type, text, length })
-- ================================================
exports('SendAlert', function(source, data)
    notify(source, 'Notification', data.text or '', data.type, data.length or data.duration)
end)

exports('DoHudText', function(source, notifyType, message)
    notify(source, 'Notification', message, notifyType, 2500)
end)

-- ================================================
-- ox_lib (server)
-- TriggerClientEvent('ox_lib:notify', source, data)
-- lime_notify server doesn't need to re-register this — the client hook catches it.
-- But if a server script calls exports['ox_lib']:notify() we can't hook that
-- as it goes directly into ox_lib's own server script.
-- ================================================

-- ================================================
-- pNotify (server)
-- TriggerClientEvent('pNotify:SendNotification', source, data)
-- Client hook catches this already. Nothing extra needed server-side.
-- ================================================

-- ================================================
-- ESX (server)
-- Some scripts call xPlayer:showNotification() or TriggerClientEvent('esx:showNotification')
-- These fire the client event which the client hook catches.
-- ================================================

-- ================================================
-- QBCore (server)
-- TriggerClientEvent('QBCore:Notify', source, message, type, duration)
-- Client hook catches this. Nothing extra needed server-side.
-- ================================================