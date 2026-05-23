--[[
    HOOK: motion_notify → lime_notify
    Catches exports['motion_notify']:Notify(...) and the net event
]]

local function forward(title, message, notifyType, duration)
    if GetResourceState("lime_notify") ~= "started" then return end
    exports['lime_notify']:Notify(title or 'Notification', message or '', notifyType or 'info', duration or 5000)
end

exports('Notify', forward)

RegisterNetEvent('motion_notify:Notify', function(title, message, notifyType, duration)
    forward(title, message, notifyType, duration)
end)
