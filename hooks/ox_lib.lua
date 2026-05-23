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

-- Override lib.notify once the resource is ready
-- lib global is created by @ox_lib/init.lua — we override after it loads
CreateThread(function()
    -- Small wait to ensure ox_lib has initialised lib global if present
    Wait(0)

    if not lib then
        -- ox_lib not loaded in this resource; nothing to hook
        return
    end

    lib.notify = function(data)
        if GetResourceState("lime_notify") ~= "started" then return end
        exports['lime_notify']:Notify(
            data.title       or 'Notification',
            data.description or '',
            resolveType(data.type),
            data.duration    or 5000
        )
    end
end)
