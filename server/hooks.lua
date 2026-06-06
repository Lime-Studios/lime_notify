--[[
    lime_notify — compatibility hooks (SERVER)

    Server-side event hooks for scripts that fire net events directly
    instead of going through another resource's export.

    Note: exports['other_resource']:Fn() cannot be intercepted from outside
    that resource. Only net events are catchable here.
]]

local function resolveType(t)
    if t == 'inform' or t == 'primary' or t == 'phone'
    or t == 'phonemessage' or t == 'neutral' then return 'info' end
    if t == 'alert' then return 'warning' end
    return t or 'info'
end

local function notify(source, title, message, notifyType, duration)
    TriggerClientEvent('lime_notify:Notify', source,
        title    or 'Notification',
        message  or '',
        resolveType(notifyType),
        duration or 5000
    )
end

-- ── motion_notify ─────────────────────────────────────────────────────────────
-- Server scripts that call exports['motion_notify']:Notify() internally fire:
-- TriggerClientEvent('motion_notify:Notify', source, title, msg, type, duration)
-- The client hook handles this. Listed here for documentation purposes only.

-- ── okokNotify ────────────────────────────────────────────────────────────────
-- Server scripts that call exports['okokNotify']:Alert() internally fire:
-- TriggerClientEvent('okokNotify:Alert', source, title, msg, duration, type)
-- The client hook handles this.

-- ── ox_lib ────────────────────────────────────────────────────────────────────
-- exports['ox_lib']:notify(source, data) is a direct call into ox_lib —
-- uncatchable from here. Server scripts that trigger the client event directly:
-- TriggerClientEvent('ox_lib:notify', source, data) are caught by the client hook.

-- ── pNotify ───────────────────────────────────────────────────────────────────
-- TriggerClientEvent('pNotify:SendNotification', source, data) — client hook catches it.

-- ── ESX ───────────────────────────────────────────────────────────────────────
-- xPlayer:showNotification() fires TriggerClientEvent('esx:showNotification') —
-- client hook catches it.

-- ── QBCore ────────────────────────────────────────────────────────────────────
-- Server scripts that do TriggerClientEvent('QBCore:Notify', source, ...) are
-- caught by the client hook.
-- Server-side TriggerEvent('QBCore:Notify', ...) has no source and cannot be
-- routed to a specific player — nothing actionable here.
