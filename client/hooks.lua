--[[
    lime_notify — compatibility hooks (CLIENT)

    EXPORT INTERCEPTION — how it works:
    ─────────────────────────────────────────────────────────────────────────────
    FiveM implements exports as local events named __cfx_export_<resource>_<fn>.
    When script A calls exports['okokNotify']:Alert(...), CFX triggers that event
    and whichever resource handles it supplies the function via a setter callback.

    If the original resource is NOT running, lime_notify registers handlers for
    those events and services the calls itself — so exports['okokNotify']:Alert()
    routes straight into lime_notify with no edits to the calling script.

    Resource coverage matches community_bridge's notify module.
    Keep the original notify resources removed to avoid double notifications.
    ─────────────────────────────────────────────────────────────────────────────
]]

-- Unknown / unregistered types fall back to 'info' (the UI does the same).
local TYPE_MAP = {
    success = 'success', positive = 'success', ok = 'success',
    error   = 'error',   failure  = 'error',   fail = 'error', negative = 'error',
    warning = 'warning', warn     = 'warning', alert = 'warning', caution = 'warning',
    info    = 'info',    inform   = 'info',    primary = 'info',
    neutral = 'info',    message  = 'info',    police  = 'info',
    phone   = 'info',    phonemessage = 'info',
    claimed = 'claimed',
}

local function resolveType(t)
    if not t then return 'info' end
    return TYPE_MAP[tostring(t):lower()] or 'info'
end

local function notify(title, message, notifyType, duration)
    exports['lime_notify']:Notify(
        title    or 'Notification',
        message  or '',
        resolveType(notifyType),
        duration or 5000
    )
end

-- Registers fn as resource `res`'s export `name`
local function provideExport(res, name, fn)
    AddEventHandler(('__cfx_export_%s_%s'):format(res, name), function(setCB)
        setCB(fn)
    end)
end

-- ══ okokNotify ═══════════════════════════════════════════════════════════════
-- exports['okokNotify']:Alert(title, message, duration, type)
provideExport('okokNotify', 'Alert', function(title, message, duration, notifyType)
    notify(title, message, notifyType, duration)
end)

RegisterNetEvent('okokNotify:Alert', function(title, message, duration, notifyType)
    notify(title, message, notifyType, duration)
end)

-- ══ motion_notify ════════════════════════════════════════════════════════════
provideExport('motion_notify', 'Notify', function(title, message, notifyType, duration)
    notify(title, message, notifyType, duration)
end)

RegisterNetEvent('motion_notify:Notify', function(title, message, notifyType, duration)
    notify(title, message, notifyType, duration)
end)

-- ══ mythic_notify ════════════════════════════════════════════════════════════
provideExport('mythic_notify', 'DoHudText', function(notifyType, message)
    notify('Notification', message, notifyType, 2500)
end)
provideExport('mythic_notify', 'DoShortHudText', function(notifyType, message)
    notify('Notification', message, notifyType, 1000)
end)
provideExport('mythic_notify', 'DoLongHudText', function(notifyType, message)
    notify('Notification', message, notifyType, 5000)
end)
provideExport('mythic_notify', 'DoCustomHudText', function(notifyType, message, length)
    notify('Notification', message, notifyType, length)
end)
provideExport('mythic_notify', 'SendAlert', function(data)
    if type(data) ~= 'table' then return end
    notify('Notification', data.text, data.type, data.length or data.duration)
end)

AddEventHandler('mythic_notify:client:SendAlert', function(data)
    if type(data) ~= 'table' then return end
    notify('Notification', data.text, data.type, data.length or data.duration)
end)

-- ══ brutal_notify ════════════════════════════════════════════════════════════
-- exports['brutal_notify']:SendAlert(title, message, time, type, sound)
provideExport('brutal_notify', 'SendAlert', function(title, message, time, notifyType, _sound)
    notify(title, message, notifyType, time)
end)

-- ══ t-notify ═════════════════════════════════════════════════════════════════
-- exports['t-notify']:Alert({ title, style, message, duration })
provideExport('t-notify', 'Alert', function(data)
    if type(data) ~= 'table' then return end
    notify(data.title, data.message, data.style, data.duration)
end)

-- t-notify also exposes Custom / Persist in some builds
provideExport('t-notify', 'Custom', function(data)
    if type(data) ~= 'table' then return end
    notify(data.title, data.message, data.style, data.duration)
end)

-- ══ r_notify ═════════════════════════════════════════════════════════════════
-- exports.r_notify:notify({ title, content, type, icon, duration, position, sound })
provideExport('r_notify', 'notify', function(data)
    if type(data) ~= 'table' then return end
    notify(data.title, data.content or data.message, data.type, data.duration)
end)

-- ══ wasabi_notify ════════════════════════════════════════════════════════════
-- exports.wasabi_notify:notify(title, message, duration, type)
provideExport('wasabi_notify', 'notify', function(title, message, duration, notifyType)
    notify(title, message, notifyType or title, duration)
end)

-- ══ FL-Notify ════════════════════════════════════════════════════════════════
-- exports['FL-Notify']:Notify(title, subtitle, message, duration, typeInt, icon)
-- typeInt: 1 = error/info, 2 = success, 3 = warning
local FL_TYPES = { [1] = 'info', [2] = 'success', [3] = 'warning' }
provideExport('FL-Notify', 'Notify', function(title, subtitle, message, duration, typeInt, _icon)
    local t = FL_TYPES[tonumber(typeInt)] or 'info'
    notify(title, message or subtitle, t, duration)
end)

-- ══ lation_ui ════════════════════════════════════════════════════════════════
-- exports.lation_ui:notify({ title, message, type, duration, position })
provideExport('lation_ui', 'notify', function(data)
    if type(data) ~= 'table' then return end
    notify(data.title, data.message, data.type, data.duration)
end)

-- ══ ZSX_UIV2 ═════════════════════════════════════════════════════════════════
-- exports['ZSX_UIV2']:Notification(title, message, icon, time)
-- ZSX passes an icon name rather than a type — map it back.
local ZSX_ICON_TYPES = {
    ['check-circle']          = 'success',
    ['times-circle']          = 'error',
    ['exclamation-triangle']  = 'warning',
    ['info']                  = 'info',
}
provideExport('ZSX_UIV2', 'Notification', function(title, message, icon, time)
    notify(title, message, ZSX_ICON_TYPES[icon] or 'info', time)
end)

-- ══ solaire_notify ═══════════════════════════════════════════════════════════
-- exports.solaire_notify:Notify({ type, title, message, duration, position, sound })
provideExport('solaire_notify', 'Notify', function(data)
    if type(data) ~= 'table' then return end
    notify(data.title, data.message, data.type, data.duration)
end)

-- ══ pNotify ══════════════════════════════════════════════════════════════════
-- exports['pNotify']:SendNotification({ text, type, timeout })
provideExport('pNotify', 'SendNotification', function(data)
    if type(data) ~= 'table' then return end
    notify('Notification', data.text, data.type, data.timeout)
end)

RegisterNetEvent('pNotify:SendNotification', function(data)
    if type(data) ~= 'table' then return end
    notify('Notification', data.text, data.type, data.timeout)
end)

AddEventHandler('pNotify:SendNotification', function(data)
    if type(data) ~= 'table' then return end
    notify('Notification', data.text, data.type, data.timeout)
end)

-- ══ ox_lib ═══════════════════════════════════════════════════════════════════
-- lib.notify() is a library function, not an export — see README integration.
RegisterNetEvent('ox_lib:notify', function(data)
    if type(data) ~= 'table' then return end
    notify(data.title, data.description, data.type, data.duration)
end)

-- ══ ESX ══════════════════════════════════════════════════════════════════════
AddEventHandler('esx:showNotification', function(message)
    notify('Notification', message, 'info', 5000)
end)

AddEventHandler('esx:showAdvancedNotification', function(sender, subject, msg)
    notify(subject or sender, msg, 'info', 5000)
end)

local function patchESX()
    if not ESX then return false end
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
    return true
end

SetTimeout(100, function()
    if not patchESX() then SetTimeout(1000, patchESX) end
end)

-- ══ QBCore / QBox ════════════════════════════════════════════════════════════
AddEventHandler('QBCore:Notify', function(message, notifyType, duration)
    local text = type(message) == 'table'
        and (message.text or message.caption or '')
        or  tostring(message or '')
    notify('Notification', text, notifyType, duration)
end)

local function patchQB()
    if not QBCore or not QBCore.Functions then return false end
    QBCore.Functions.Notify = function(message, notifyType, duration)
        local text = type(message) == 'table'
            and (message.text or message.caption or '')
            or  tostring(message or '')
        notify('Notification', text, notifyType, duration)
    end
    return true
end

SetTimeout(100, function()
    if not patchQB() then SetTimeout(1000, patchQB) end
end)
