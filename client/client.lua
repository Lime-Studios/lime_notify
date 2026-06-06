local currentPosition  = nil
local menuPosition     = nil
local soundEnabled     = true
local soundVolume      = 50
local notifSize        = 100
local notifStyle       = 'default'
local nuiLoaded        = false

local POSITION_MAP = {
    ['top-left']      = { x = 5,  y = 5  },
    ['top-center']    = { x = 50, y = 5  },
    ['top-right']     = { x = 95, y = 5  },
    ['middle-left']   = { x = 5,  y = 50 },
    ['middle-center'] = { x = 50, y = 50 },
    ['middle-right']  = { x = 95, y = 50 },
    ['bottom-left']   = { x = 5,  y = 95 },
    ['bottom-center'] = { x = 50, y = 95 },
    ['bottom-right']  = { x = 95, y = 95 },
}

local VALID_STYLES = {
    ['default'] = true, ['minimal'] = true, ['glass'] = true,
    ['toast']   = true, ['bold']    = true, ['retro'] = true,
}

local STYLE_TO_INT = {
    ['default'] = 1, ['minimal'] = 2, ['glass'] = 3,
    ['toast']   = 4, ['bold']    = 5, ['retro'] = 6,
}
local INT_TO_STYLE = {}
for k, v in pairs(STYLE_TO_INT) do INT_TO_STYLE[v] = k end

local function styleToInt(style) return STYLE_TO_INT[style] or 1 end

RegisterNUICallback('nuiReady', function(_, cb)
    nuiLoaded = true
    cb('ok')
end)

-- One-shot: fires once then the thread is gone
SetTimeout(500, function()
    if not nuiLoaded then
        SendNUIMessage({ action = 'ping' })
    end
end)

local function waitForNui()
    if nuiLoaded then return true end
    local timeout = 0
    while not nuiLoaded and timeout < 10000 do
        Wait(10)
        timeout = timeout + 10
    end
    if not nuiLoaded then
        print('[lime_notify] WARNING: NUI failed to signal ready after 10s.')
        return false
    end
    return true
end

local function getPosition()
    if currentPosition then return currentPosition end
    local x = GetResourceKvpInt('lime_notify_x')
    local y = GetResourceKvpInt('lime_notify_y')
    if x <= 0 or y <= 0 then
        local preset = Config and Config.Position and POSITION_MAP[Config.Position]
        x = preset and preset.x or 95
        y = preset and preset.y or 5
        SetResourceKvpInt('lime_notify_x', x)
        SetResourceKvpInt('lime_notify_y', y)
    end
    currentPosition = { x = math.max(5, math.min(95, x)), y = math.max(5, math.min(95, y)) }
    return currentPosition
end

local function getMenuPosition()
    if menuPosition then return menuPosition end
    local x = GetResourceKvpInt('lime_notify_menu_x')
    local y = GetResourceKvpInt('lime_notify_menu_y')
    if x <= 0 then x = 20 end
    if y <= 0 then y = 20 end
    SetResourceKvpInt('lime_notify_menu_x', x)
    SetResourceKvpInt('lime_notify_menu_y', y)
    menuPosition = { x = x, y = y }
    return menuPosition
end

local function getSoundSettings()
    local storedSound  = GetResourceKvpInt('lime_notify_sound')
    local storedVolume = GetResourceKvpInt('lime_notify_volume')
    soundEnabled = (storedSound ~= 2)
    if storedVolume < 1 or storedVolume > 100 then storedVolume = 50 end
    soundVolume = storedVolume
    return soundEnabled, soundVolume
end

local function getSize()
    local stored = GetResourceKvpInt('lime_notify_size')
    if stored < 75 or stored > 200 then stored = 100 end
    notifSize = stored
    return notifSize
end

local function getStyle()
    if Config and Config.AllowPlayerStyle == false then
        local cfgStyle = Config.Style
        notifStyle = (cfgStyle and VALID_STYLES[cfgStyle]) and cfgStyle or 'default'
        return notifStyle
    end
    local stored = GetResourceKvpInt('lime_notify_style')
    if stored and stored >= 1 and INT_TO_STYLE[stored] then
        notifStyle = INT_TO_STYLE[stored]
    else
        local cfgStyle = Config and Config.Style
        notifStyle = (cfgStyle and VALID_STYLES[cfgStyle]) and cfgStyle or 'default'
        SetResourceKvpInt('lime_notify_style', styleToInt(notifStyle))
    end
    return notifStyle
end

RegisterNUICallback('saveSettings', function(data, cb)
    local x      = math.max(5,   math.min(95,  math.floor(tonumber(data.x)      or 95)))
    local y      = math.max(5,   math.min(95,  math.floor(tonumber(data.y)      or 5)))
    local menuX  = math.floor(tonumber(data.menuX)  or 20)
    local menuY  = math.floor(tonumber(data.menuY)  or 20)
    local volume = math.max(0,   math.min(100, math.floor(tonumber(data.volume) or 50)))
    local size   = math.max(75,  math.min(200, math.floor(tonumber(data.size)   or 100)))
    local style  = (data.style and VALID_STYLES[data.style]) and data.style or notifStyle

    soundEnabled    = data.sound == true
    soundVolume     = volume
    notifSize       = size
    notifStyle      = style
    currentPosition = nil
    menuPosition    = nil

    SetResourceKvpInt('lime_notify_x',      x)
    SetResourceKvpInt('lime_notify_y',      y)
    SetResourceKvpInt('lime_notify_menu_x', menuX)
    SetResourceKvpInt('lime_notify_menu_y', menuY)
    SetResourceKvpInt('lime_notify_sound',  soundEnabled and 1 or 2)
    SetResourceKvpInt('lime_notify_volume', volume)
    SetResourceKvpInt('lime_notify_size',   size)
    SetResourceKvpInt('lime_notify_style',  styleToInt(style))

    SendNUIMessage({
        action = 'updateSettings',
        sound  = soundEnabled,
        volume = soundVolume,
        size   = notifSize,
        style  = notifStyle,
    })

    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeEditor', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

local function Notify(title, message, notifyType, duration, style)
    if not waitForNui() then
        print('[lime_notify] Skipping notify - NUI not ready. Title: ' .. tostring(title))
        return
    end

    local pos      = getPosition()
    local snd, vol = getSoundSettings()
    local sz       = getSize()
    local st       = style or getStyle()
    if not VALID_STYLES[st] then st = getStyle() end

    SendNUIMessage({
        action   = 'notify',
        type     = notifyType or 'info',
        title    = title      or 'Notification',
        message  = message    or '',
        duration = duration   or 5000,
        position = { x = pos.x, y = pos.y },
        sound    = snd,
        volume   = vol,
        size     = sz,
        style    = st,
    })
end

exports('Notify', Notify)

RegisterNetEvent('lime_notify:Notify', function(title, message, notifyType, duration, style)
    Notify(title, message, notifyType, duration, style)
end)

RegisterCommand('testnotify', function()
    Notify('Success!',    'This is a success message', 'success', 5000)
    Notify('Information', 'This is an info message',   'info',    5000)
    Notify('Warning',     'This is a warning message', 'warning', 5000)
    Notify('Error :(',    'This is an error message',  'error',   5000)
end)

RegisterCommand('editnotify', function()
    if not waitForNui() then return end
    local pos        = getPosition()
    local menuPos    = getMenuPosition()
    local snd, vol   = getSoundSettings()
    local sz         = getSize()
    local st         = getStyle()
    local allowStyle = not (Config and Config.AllowPlayerStyle == false)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action     = 'openEditor',
        x          = pos.x,
        y          = pos.y,
        menuX      = menuPos.x,
        menuY      = menuPos.y,
        sound      = snd,
        volume     = vol,
        size       = sz,
        style      = st,
        allowStyle = allowStyle,
    })
end)

RegisterCommand('resetnotify', function()
    local preset   = (Config and Config.Position and POSITION_MAP[Config.Position]) or { x = 95, y = 5 }
    local defStyle = (Config and Config.Style and VALID_STYLES[Config.Style]) and Config.Style or 'default'

    SetResourceKvpInt('lime_notify_x',      preset.x)
    SetResourceKvpInt('lime_notify_y',      preset.y)
    SetResourceKvpInt('lime_notify_menu_x', 20)
    SetResourceKvpInt('lime_notify_menu_y', 20)
    SetResourceKvpInt('lime_notify_sound',  1)
    SetResourceKvpInt('lime_notify_volume', 50)
    SetResourceKvpInt('lime_notify_size',   100)
    SetResourceKvpInt('lime_notify_style',  styleToInt(defStyle))

    currentPosition = nil
    menuPosition    = nil
    soundEnabled    = true
    soundVolume     = 50
    notifSize       = 100
    notifStyle      = defStyle

    Notify('Reset Settings', 'Settings reset to default.', 'success', 5000)
end)
