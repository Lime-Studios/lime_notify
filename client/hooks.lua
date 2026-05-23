--[[
    lime_notify — compatibility hooks (CLIENT)
    
    These live inside lime_notify itself. FiveM exports are scoped to the
    declaring resource, so the only way to intercept exports['other_script']:Fn()
    is to declare those same exports here, making lime_notify respond to them.

    Each section covers one popular notify script.
    
    NOTE: Uses exports['lime_notify']:Notify() rather than the local Notify()
    function, since that local is not accessible across files.
]]

local function resolveType(t)
    if t == 'inform' or t == 'primary' or t == 'phone' or t == 'phonemessage' or t == 'neutral' or t == 'alert' then
        return 'info'
    end
    return t or 'info'
end

local function notify(title, message, notifyType, duration)
    exports['lime_notify']:Notify(title or 'Notification', message or '', resolveType(notifyType), duration or 5000)
end

-- ================================================
-- motion_notify
-- exports['motion_notify']:Notify(title, msg, type, duration)
-- TriggerClientEvent('motion_notify:Notify', src, title, msg, type, duration)
-- ================================================
exports('motion_notify_Notify', function(title, message, notifyType, duration)
    notify(title, message, notifyType, duration)
end)

RegisterNetEvent('motion_notify:Notify', function(title, message, notifyType, duration)
    notify(title, message, notifyType, duration)
end)

-- ================================================
-- okokNotify
-- exports['okokNotify']:Alert(title, msg, duration, type)
-- TriggerClientEvent('okokNotify:Alert', src, title, msg, duration, type)
-- Note: duration and type are in different positions vs lime_notify!
-- ================================================
exports('Alert', function(title, message, duration, notifyType)
    notify(title, message, notifyType, duration)
end)

RegisterNetEvent('okokNotify:Alert', function(title, message, duration, notifyType)
    notify(title, message, notifyType, duration)
end)

-- ================================================
-- mythic_notify
-- exports['mythic_notify']:DoHudText(type, message)
-- exports['mythic_notify']:SendAlert({ type, text, length })
-- TriggerClientEvent('mythic_notify:client:SendAlert', src, { type, text, length })
-- ================================================
exports('DoHudText', function(notifyType, message)
    notify('Notification', message, notifyType, 2500)
end)

exports('DoShortHudText', function(notifyType, message)
    notify('Notification', message, notifyType, 1000)
end)

exports('DoLongHudText', function(notifyType, message)
    notify('Notification', message, notifyType, 5000)
end)

exports('DoCustomHudText', function(notifyType, message, length)
    notify('Notification', message, notifyType, length)
end)

exports('SendAlert', function(data)
    notify('Notification', data.text or '', data.type, data.length or data.duration)
end)

RegisterNetEvent('mythic_notify:client:SendAlert', function(data)
    notify('Notification', data.text or '', data.type, data.length or data.duration)
end)

-- ================================================
-- ox_lib (server-side only — client lib.notify() must be edited in ox_lib itself)
-- TriggerClientEvent('ox_lib:notify', src, { title, description, type, duration })
-- ================================================
RegisterNetEvent('ox_lib:notify', function(data)
    notify(data.title or 'Notification', data.description or '', data.type, data.duration)
end)

-- ================================================
-- pNotify
-- TriggerEvent('pNotify:SendNotification', { text, type, timeout })
-- TriggerClientEvent('pNotify:SendNotification', src, { text, type, timeout })
-- ================================================
RegisterNetEvent('pNotify:SendNotification', function(data)
    notify('Notification', data.text or '', data.type, data.timeout)
end)

AddEventHandler('pNotify:SendNotification', function(data)
    notify('Notification', data.text or '', data.type, data.timeout)
end)

-- ================================================
-- ESX
-- ESX.ShowNotification and ESX.ShowAdvancedNotification patched at runtime
-- ================================================
CreateThread(function()
    Wait(100)

    if ESX then
        if ESX.ShowNotification then
            ESX.ShowNotification = function(message, notifyType, duration)
                notify('Notification', message, notifyType, duration)
            end
        end

        if ESX.ShowAdvancedNotification then
            ESX.ShowAdvancedNotification = function(sender, subject, msg)
                notify(subject or sender or 'Notification', msg or '', 'info', 5000)
            end
        end
    end
end)

AddEventHandler('esx:showNotification', function(message)
    notify('Notification', message, 'info', 5000)
end)

AddEventHandler('esx:showAdvancedNotification', function(sender, subject, msg)
    notify(subject or sender or 'Notification', msg or '', 'info', 5000)
end)

-- ================================================
-- QBCore
-- QBCore.Functions.Notify patched at runtime
-- ================================================
CreateThread(function()
    Wait(100)

    if QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify = function(message, notifyType, duration)
            local text = type(message) == 'table' and (message.text or message.caption or '') or tostring(message or '')
            notify('Notification', text, notifyType, duration)
        end
    end
end)

AddEventHandler('QBCore:Notify', function(message, notifyType, duration)
    local text = type(message) == 'table' and (message.text or message.caption or '') or tostring(message or '')
    notify('Notification', text, notifyType, duration)
end)