--[[
    HOOK: ESX notifications → lime_notify
    Covers:
      ESX.ShowNotification(message)                    -- basic ESX notify
      ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
      TriggerEvent('esx:showNotification', message)
      TriggerEvent('esx:showAdvancedNotification', ...)
]]

-- Wait for ESX to be available
CreateThread(function()
    Wait(0)

    -- Hook ESX.ShowNotification
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification = function(message, notifyType, duration)
            if GetResourceState("lime_notify") ~= "started" then return end
            exports['lime_notify']:Notify('Notification', message or '', notifyType or 'info', duration or 5000)
        end
    end

    -- Hook ESX.ShowAdvancedNotification (collapse to a simple notify)
    if ESX and ESX.ShowAdvancedNotification then
        ESX.ShowAdvancedNotification = function(sender, subject, msg, _, _, _, _, _)
            if GetResourceState("lime_notify") ~= "started" then return end
            local title   = subject or sender or 'Notification'
            local message = msg or ''
            exports['lime_notify']:Notify(title, message, 'info', 5000)
        end
    end
end)

-- Net event fallbacks (for scripts that trigger directly rather than via ESX global)
AddEventHandler('esx:showNotification', function(message)
    if GetResourceState("lime_notify") ~= "started" then return end
    exports['lime_notify']:Notify('Notification', message or '', 'info', 5000)
end)

AddEventHandler('esx:showAdvancedNotification', function(sender, subject, msg)
    if GetResourceState("lime_notify") ~= "started" then return end
    exports['lime_notify']:Notify(subject or sender or 'Notification', msg or '', 'info', 5000)
end)
