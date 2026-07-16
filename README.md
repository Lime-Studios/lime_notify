# Lime Notify - Modern FiveM Notification System

A sleek, modern notification system for FiveM with sound support and multiple positioning options.
https://discord.gg/fqUsy3FuYn

## Installation

1. Download and extract to your FiveM resources folder
2. Rename the folder to `lime_notify`
3. Add `ensure lime_notify` to your `server.cfg`
4. Restart your server

## Usage

### Client Side

```lua
-- Basic usage
exports['lime_notify']:Notify('Success', 'Action completed!', 'success')

-- With duration
exports['lime_notify']:Notify('Warning', 'Be careful!', 'warning', 7000)
```

### Server Side

```lua
-- Send to specific player
exports['lime_notify']:Notify(source, 'Server Message', 'Hello!', 'success', 5000)

-- Send to all players
for _, playerId in ipairs(GetPlayers()) do
    exports['lime_notify']:Notify(playerId, 'Announcement', 'Server restart in 5 minutes', 'warning', 10000)
end
```

## Drop-in Compatibility

lime_notify intercepts other notification resources' exports directly, so scripts
calling them keep working with no edits. **Remove the original resource** — if it's
still running you'll get two notifications.

| Resource | Intercepted export |
|----------|--------------------|
| okokNotify | `Alert(title, msg, duration, type)` |
| mythic_notify | `DoHudText`, `DoShortHudText`, `DoLongHudText`, `DoCustomHudText`, `SendAlert` |
| brutal_notify | `SendAlert(title, msg, time, type, sound)` |
| t-notify | `Alert({ title, style, message, duration })` |
| r_notify | `notify({ title, content, type, duration })` |
| wasabi_notify | `notify(title, msg, duration, type)` |
| FL-Notify | `Notify(title, subtitle, msg, duration, typeInt, icon)` |
| lation_ui | `notify({ title, message, type, duration })` |
| ZSX_UIV2 | `Notification(title, message, icon, time)` |
| solaire_notify | `Notify({ type, title, message, duration })` |
| pNotify | `SendNotification({ text, type, timeout })` |
| motion_notify | `Notify(title, msg, type, duration)` |

Framework notifications are patched at runtime:

| Framework | Patched |
|-----------|---------|
| ESX | `ESX.ShowNotification`, `ESX.ShowAdvancedNotification` + legacy events |
| QBCore / QBox | `QBCore.Functions.Notify` + `QBCore:Notify` event |

**ox_lib** needs the manual integration below (`lib.notify` is a library function,
not an export, so it can't be intercepted).

## ox_lib Integration

1. Open `ox_lib/resource/interface/client` and find the `lib.notify` function
2. Replace it with the following code
3. Restart your server

```lua
function lib.notify(data)
    if GetResourceState("lime_notify") ~= "started" then
        return
    end
    local notifyType = data.type or 'info'
    if notifyType == 'inform' then notifyType = 'info' end

    exports['lime_notify']:Notify(
        data.title or 'Notification',
        data.description or '',
        notifyType,
        data.duration or 5000
    )
end
```

## Exports List

### Client-Side Exports
```lua
-- Returns a notification id. duration = 0 keeps it on screen until dismissed.
local id = exports['lime_notify']:Notify(title, message, type, duration, style)

-- Progress notification — fill bar over the duration, auto-dismisses. Returns id.
local id = exports['lime_notify']:Progress(title, message, duration, type, style)

-- Dismiss a notification by id (for sticky or early removal)
exports['lime_notify']:Dismiss(id)
```

### Server-Side Exports
```lua
exports['lime_notify']:Notify(source, title, message, type, duration, style)
exports['lime_notify']:Progress(source, title, message, duration, type, style)
```

### Click events
```lua
-- Fires when a player clicks a notification
AddEventHandler('lime_notify:clicked', function(id)
    -- open a phone, a menu, etc.
end)
```

### Rich text
Messages support `**bold**` and GTA-style colour codes:
`~r~red ~g~green ~b~blue ~y~yellow ~o~orange ~p~purple ~w~white ~s~reset`

### Automatic behaviours
- Identical repeated notifications collapse into one card with a ×N counter
- More than 5 at once queues the rest behind a "+N more" chip

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| title | string | Notification title |
| message | string | Notification message |
| type | string | `success` `error` `warning` `info` `claimed` — anything unrecognised becomes `info` |
| duration | number | Duration in milliseconds (default: 5000) |

## Commands

| Command | Description |
|---------|-------------|
| `/editnotify` | Open the position, style and sound editor |
| `/resetnotify` | Reset all settings to server defaults |
| `/testnotify` | Show a test notification for each type |

## Support

For issues or questions, open a ticket in our Discord: https://discord.gg/fqUsy3FuYn

## License
GNU GPL v3
