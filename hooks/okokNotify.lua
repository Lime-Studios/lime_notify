--[[
    HOOK: okokNotify → lime_notify
    okokNotify signature: exports['okokNotify']:Alert(title, message, duration, type)
    Note: duration and type are swapped vs lime_notify
    Types: success, info, warning, error, phone → mapped straight through
]]

local function resolveType(t)
    -- okokNotify has a 'phone' type (orange) — map to 'info' as closest
    if t == 'phone' then return 'info' end
    return t or 'info'
end

local function forward(title, message, duration, notifyType)
    if GetResourceState("lime_notify") ~= "started" then return end
    exports['lime_notify']:Notify(title or 'Notification', message or '', resolveType(notifyType), duration or 5000)
end

-- Client export: exports['okokNotify']:Alert(title, message, duration, type)
exports('Alert', forward)

-- Server net event: TriggerClientEvent('okokNotify:Alert', source, title, message, duration, type)
RegisterNetEvent('okokNotify:Alert', function(title, message, duration, notifyType)
    forward(title, message, duration, notifyType)
end)
