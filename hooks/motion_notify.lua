--[[
    motion_notify → lime_notify compatibility hook
    -----------------------------------------------
    Intercepts calls that target motion_notify and forwards
    them to lime_notify.
]]
 
-- ================================
-- Net event hook
-- ================================
RegisterNetEvent('motion_notify:Notify', function(title, message, notifyType, duration)
    TriggerEvent('lime_notify:Notify', title, message, notifyType, duration)
end)
 
-- ================================
-- Export hook
-- ================================
-- Catches: exports['motion_notify']:Notify(...)
exports('Notify', function(title, message, notifyType, duration)
    if GetResourceState("lime_notify") ~= "started" then
        print("[hooks/motion_notify] WARNING: lime_notify is not started, skipping notify.")
        return
    end
 
    exports['lime_notify']:Notify(
        title       or 'Notification',
        message     or '',
        notifyType  or 'info',
        duration    or 5000
    )
end)
 