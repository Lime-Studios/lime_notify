--[[
    HOOK: pNotify → lime_notify
    pNotify sends a NUI message directly — there is no export, only a net event:
      TriggerEvent('pNotify:SendNotification', { text, type, timeout, layout })
    Types: success, info, warning, error, alert → mapped
]]

local function resolveType(t)
    -- pNotify uses 'alert' as a generic type
    if t == 'alert' then return 'info' end
    return t or 'info'
end

RegisterNetEvent('pNotify:SendNotification', function(data)
    if GetResourceState("lime_notify") ~= "started" then return end
    exports['lime_notify']:Notify(
        'Notification',
        data.text    or '',
        resolveType(data.type),
        data.timeout or 5000
    )
end)

-- Some servers trigger it as a client event from the server side
RegisterNetEvent('pNotify:SendNotification')
AddEventHandler('pNotify:SendNotification', function(data)
    if GetResourceState("lime_notify") ~= "started" then return end
    exports['lime_notify']:Notify(
        'Notification',
        data.text    or '',
        resolveType(data.type),
        data.timeout or 5000
    )
end)
