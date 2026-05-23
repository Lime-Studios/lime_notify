--[[
    HOOK: ox_lib → lime_notify
    ox_lib signature: lib.notify({ title, description, type, duration, id })
    'lib' is a global table provided by ox_lib's init.lua.
    This hook overrides lib.notify if ox_lib is present, or defines it standalone.
]]

local function resolveType(t)
    if t == 'inform' then return 'info' end
    return t or 'info'
end
 
-- Catches: TriggerClientEvent('ox_lib:notify', source, data) from server-side scripts
RegisterNetEvent('ox_lib:notify', function(data)
    if GetResourceState("lime_notify") ~= "started" then return end
    exports['lime_notify']:Notify(
        data.title       or 'Notification',
        data.description or '',
        resolveType(data.type),
        data.duration    or 5000
    )
end)
