--[[
    HOOK: QBCore / qb-notify → lime_notify
    Covers:
      QBCore.Functions.Notify(message, type, duration)
      TriggerEvent('QBCore:Notify', message, type, duration)
    Types: primary → info, inform → info, others pass through
]]

local function resolveType(t)
    if t == 'primary' or t == 'inform' then return 'info' end
    return t or 'info'
end

CreateThread(function()
    Wait(0)

    -- Hook QBCore.Functions.Notify if QBCore is available
    if QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify = function(message, notifyType, duration)
            if GetResourceState("lime_notify") ~= "started" then return end
            -- message can be a string or table { text, caption }
            local text = type(message) == 'table' and (message.text or message.caption or '') or tostring(message)
            exports['lime_notify']:Notify('Notification', text, resolveType(notifyType), duration or 5000)
        end
    end
end)

-- Net event: TriggerEvent('QBCore:Notify', message, type, duration)
AddEventHandler('QBCore:Notify', function(message, notifyType, duration)
    if GetResourceState("lime_notify") ~= "started" then return end
    local text = type(message) == 'table' and (message.text or message.caption or '') or tostring(message)
    exports['lime_notify']:Notify('Notification', text, resolveType(notifyType), duration or 5000)
end)
