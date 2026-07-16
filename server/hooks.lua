--[[
    lime_notify — compatibility hooks (SERVER)

    Uses the __cfx_export_ mechanism to service other notify scripts'
    SERVER exports when those resources are not running.
]]

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

local function notify(source, title, message, notifyType, duration)
    TriggerClientEvent('lime_notify:Notify', source,
        title    or 'Notification',
        message  or '',
        resolveType(notifyType),
        duration or 5000
    )
end

local function provideExport(res, name, fn)
    AddEventHandler(('__cfx_export_%s_%s'):format(res, name), function(setCB)
        setCB(fn)
    end)
end

-- ══ okokNotify ═══════════════════════════════════════════════════════════════
provideExport('okokNotify', 'Alert', function(source, title, message, duration, notifyType)
    notify(source, title, message, notifyType, duration)
end)

-- ══ motion_notify ════════════════════════════════════════════════════════════
provideExport('motion_notify', 'Notify', function(source, title, message, notifyType, duration)
    notify(source, title, message, notifyType, duration)
end)

-- ══ mythic_notify ════════════════════════════════════════════════════════════
provideExport('mythic_notify', 'SendAlert', function(source, data)
    if type(data) ~= 'table' then return end
    notify(source, 'Notification', data.text, data.type, data.length or data.duration)
end)

provideExport('mythic_notify', 'DoHudText', function(source, notifyType, message)
    notify(source, 'Notification', message, notifyType, 2500)
end)

-- ══ brutal_notify ════════════════════════════════════════════════════════════
provideExport('brutal_notify', 'SendAlert', function(source, title, message, time, notifyType, _sound)
    notify(source, title, message, notifyType, time)
end)

-- ══ t-notify ═════════════════════════════════════════════════════════════════
provideExport('t-notify', 'Alert', function(source, data)
    if type(data) ~= 'table' then return end
    notify(source, data.title, data.message, data.style, data.duration)
end)

-- ══ r_notify ═════════════════════════════════════════════════════════════════
provideExport('r_notify', 'notify', function(source, data)
    if type(data) ~= 'table' then return end
    notify(source, data.title, data.content or data.message, data.type, data.duration)
end)

-- ══ wasabi_notify ════════════════════════════════════════════════════════════
provideExport('wasabi_notify', 'notify', function(source, title, message, duration, notifyType)
    notify(source, title, message, notifyType or title, duration)
end)

-- ══ FL-Notify ════════════════════════════════════════════════════════════════
local FL_TYPES = { [1] = 'info', [2] = 'success', [3] = 'warning' }
provideExport('FL-Notify', 'Notify', function(source, title, subtitle, message, duration, typeInt, _icon)
    notify(source, title, message or subtitle, FL_TYPES[tonumber(typeInt)] or 'info', duration)
end)

-- ══ lation_ui ════════════════════════════════════════════════════════════════
provideExport('lation_ui', 'notify', function(source, data)
    if type(data) ~= 'table' then return end
    notify(source, data.title, data.message, data.type, data.duration)
end)

-- ══ ZSX_UIV2 ═════════════════════════════════════════════════════════════════
local ZSX_ICON_TYPES = {
    ['check-circle']         = 'success',
    ['times-circle']         = 'error',
    ['exclamation-triangle'] = 'warning',
    ['info']                 = 'info',
}
provideExport('ZSX_UIV2', 'Notification', function(source, title, message, icon, time)
    notify(source, title, message, ZSX_ICON_TYPES[icon] or 'info', time)
end)

-- ══ solaire_notify ═══════════════════════════════════════════════════════════
provideExport('solaire_notify', 'Notify', function(source, data)
    if type(data) ~= 'table' then return end
    notify(source, data.title, data.message, data.type, data.duration)
end)

-- ══ pNotify ══════════════════════════════════════════════════════════════════
provideExport('pNotify', 'SendNotification', function(source, data)
    if type(data) ~= 'table' then return end
    notify(source, 'Notification', data.text, data.type, data.timeout)
end)

-- ox_lib server: lib.notify(source, data) triggers the 'ox_lib:notify' client
-- event — caught by the client hook. ESX xPlayer:showNotification and QBCore
-- TriggerClientEvent('QBCore:Notify') likewise route through client hooks.
