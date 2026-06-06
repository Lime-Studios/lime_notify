--[[
    lime_notify — compatibility hooks (CLIENT)

    Catches events fired by other notification scripts so servers can
    drop in lime_notify without editing every script that calls them.

    Safe as long as the original notify resource is not ALSO running —
    if it is, both resources would catch the event and show a notification.
    The assumption is lime_notify is replacing those resources, not running
    alongside them.

    ESX and QBCore are patched on the global object directly, which is
    cleaner and works even for client-side calls.
]]

local function resolveType(t)
    if t == 'inform' or t == 'primary' or t == 'phone'
    or t == 'phonemessage' or t == 'neutral' then return 'info' end
    if t == 'alert' then return 'warning' end
    return t or 'info'
end

local function notify(title, message, notifyType, duration)
    exports['lime_notify']:Notify(
        title    or 'Notification',
        message  or '',
        resolveType(notifyType),
        duration or 5000
    )
end

-- ── mythic_notify ─────────────────────────────────────────────────────────────
-- TriggerClientEvent('mythic_notify:client:SendAlert', src, { type, text, length })

AddEventHandler('mythic_notify:client:SendAlert', function(data)
    if type(data) ~= 'table' then return end
    notify('Notification', data.text, data.type, data.length or data.duration)
end)

-- ── okokNotify ────────────────────────────────────────────────────────────────
-- TriggerClientEvent('okokNotify:Alert', src, title, msg, duration, type)

RegisterNetEvent('okokNotify:Alert', function(title, message, duration, notifyType)
    notify(title, message, notifyType, duration)
end)

-- ── ox_lib ────────────────────────────────────────────────────────────────────
-- TriggerClientEvent('ox_lib:notify', src, { title, description, type, duration })

RegisterNetEvent('ox_lib:notify', function(data)
    if type(data) ~= 'table' then return end
    notify(data.title, data.description, data.type, data.duration)
end)

-- ── pNotify ───────────────────────────────────────────────────────────────────
-- TriggerClientEvent / TriggerEvent('pNotify:SendNotification', { text, type, timeout })

RegisterNetEvent('pNotify:SendNotification', function(data)
    if type(data) ~= 'table' then return end
    notify('Notification', data.text, data.type, data.timeout)
end)

AddEventHandler('pNotify:SendNotification', function(data)
    if type(data) ~= 'table' then return end
    notify('Notification', data.text, data.type, data.timeout)
end)

-- ── ESX ───────────────────────────────────────────────────────────────────────

AddEventHandler('esx:showNotification', function(message)
    notify('Notification', message, 'info', 5000)
end)

AddEventHandler('esx:showAdvancedNotification', function(sender, subject, msg)
    notify(subject or sender, msg, 'info', 5000)
end)

SetTimeout(100, function()
    if ESX then
        if ESX.ShowNotification then
            ESX.ShowNotification = function(message, notifyType, duration)
                notify('Notification', message, notifyType, duration)
            end
        end
        if ESX.ShowAdvancedNotification then
            ESX.ShowAdvancedNotification = function(sender, subject, msg)
                notify(subject or sender, msg, 'info', 5000)
            end
        end
    else
        SetTimeout(1000, function()
            if not ESX then return end
            if ESX.ShowNotification then
                ESX.ShowNotification = function(message, notifyType, duration)
                    notify('Notification', message, notifyType, duration)
                end
            end
            if ESX.ShowAdvancedNotification then
                ESX.ShowAdvancedNotification = function(sender, subject, msg)
                    notify(subject or sender, msg, 'info', 5000)
                end
            end
        end)
    end
end)

-- ── QBCore / QBox ─────────────────────────────────────────────────────────────

AddEventHandler('QBCore:Notify', function(message, notifyType, duration)
    local text = type(message) == 'table'
        and (message.text or message.caption or '')
        or  tostring(message or '')
    notify('Notification', text, notifyType, duration)
end)

SetTimeout(100, function()
    if QBCore and QBCore.Functions then
        QBCore.Functions.Notify = function(message, notifyType, duration)
            local text = type(message) == 'table'
                and (message.text or message.caption or '')
                or  tostring(message or '')
            notify('Notification', text, notifyType, duration)
        end
    else
        SetTimeout(1000, function()
            if not QBCore or not QBCore.Functions then return end
            QBCore.Functions.Notify = function(message, notifyType, duration)
                local text = type(message) == 'table'
                    and (message.text or message.caption or '')
                    or  tostring(message or '')
                notify('Notification', text, notifyType, duration)
            end
        end)
    end
end)
