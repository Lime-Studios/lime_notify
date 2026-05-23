--[[
    HOOK: mythic_notify → lime_notify
    mythic_notify signatures:
      exports['mythic_notify']:DoHudText(type, message)
      TriggerEvent('mythic_notify:client:SendAlert', { type, text, duration })
    Types: 'inform' → 'info', others pass through
]]

local function resolveType(t)
    if t == 'inform' then return 'info' end
    return t or 'info'
end

-- exports['mythic_notify']:DoHudText(type, message)
exports('DoHudText', function(notifyType, message)
    if GetResourceState("lime_notify") ~= "started" then return end
    exports['lime_notify']:Notify('Notification', message or '', resolveType(notifyType), 5000)
end)

-- TriggerEvent('mythic_notify:client:SendAlert', { type, text, duration })
RegisterNetEvent('mythic_notify:client:SendAlert', function(data)
    if GetResourceState("lime_notify") ~= "started" then return end
    exports['lime_notify']:Notify(
        'Notification',
        data.text     or '',
        resolveType(data.type),
        data.duration or 5000
    )
end)

-- Server-side trigger variant
RegisterNetEvent('mythic_notify:server:SendAlert', function(data)
    if GetResourceState("lime_notify") ~= "started" then return end
    exports['lime_notify']:Notify(
        'Notification',
        data.text     or '',
        resolveType(data.type),
        data.duration or 5000
    )
end)
