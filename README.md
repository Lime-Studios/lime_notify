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
- `exports['lime_notify']:Notify(title, message, type, duration)`

### Server-Side Exports
- `exports['lime_notify']:Notify(source, title, message, type, duration)`

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| title | string | Notification title |
| message | string | Notification message |
| type | string | `success` `error` `warning` `info` `claimed` |
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
