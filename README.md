# RBXPerms

A flexible and extensible permissions system for Roblox games. RBXPerms allows you to define and evaluate complex permission requirements using a simple string-based syntax.

## Installation

1. Download or clone this repository
2. Copy the `RBXPerms` folder into your game's `ReplicatedStorage` or `ServerScriptService`
3. Require the module in your scripts

## Basic Usage

```lua
local RBXPerms = require(path.to.RBXPerms)

-- Check permissions for a specific player (server-side)
local player = game.Players:GetPlayerByName("PlayerName")
local hasPermission = RBXPerms(player, {
    "Group:123456",
    "Badge:987654"
})

if hasPermission then
    print("Player has all required permissions!")
end

-- Check permissions for local player (client-side)
local hasPermission = RBXPerms({
    "UserId:123456"
})
```

## Permission Syntax

Permissions are defined as strings with the following format:
```
PermissionType:argument1:argument2:...
```

- **PermissionType**: The type of permission (e.g., `Badge`, `Group`, `UserId`)
- **Arguments**: Colon-separated values specific to the permission type
- **Negation**: Prefix with `!` to check for absence (e.g., `!Badge:123456`)

## Built-in Permission Types

### Badge
Check if a player has a specific badge.

```lua
RBXPerms(player, {
    "Badge:123456"  -- Player must have badge ID 123456
})

-- Negation: Player must NOT have the badge
RBXPerms(player, {
    "!Badge:123456"
})
```

### Group
Check if a player is in a group and optionally verify their rank.

```lua
-- Check if player is in a group (any rank > 0)
RBXPerms(player, {
    "Group:123456"
})

-- Check if player has exact rank
RBXPerms(player, {
    "Group:123456:255"  -- Must be rank 255
})

-- Check if player has rank greater than or equal to value
RBXPerms(player, {
    "Group:123456:>=100"  -- Rank must be >= 100
})

-- Check if player has rank less than value
RBXPerms(player, {
    "Group:123456:<50"  -- Rank must be < 50
})

-- Check if player's rank is in range
RBXPerms(player, {
    "Group:123456:10-50"  -- Rank must be between 10 and 50 (inclusive)
})

-- Negation: Player must NOT be in the group
RBXPerms(player, {
    "!Group:123456"
})
```

### UserId
Check if a player's UserId matches one or more IDs.

```lua
-- Check for a single UserId
RBXPerms(player, {
    "UserId:123456"
})

-- Check for multiple UserIds (OR condition)
RBXPerms(player, {
    "UserId:123456,789012,345678"
})

-- Negation: Player must NOT be this UserId
RBXPerms(player, {
    "!UserId:123456"
})
```

## Combining Multiple Permissions

By default, **all** permissions in the table must be satisfied (AND condition):

```lua
RBXPerms(player, {
    "Group:123456:>=100",  -- Must be in group with rank >= 100
    "Badge:987654",         -- AND must have this badge
    "!UserId:111111"        -- AND must NOT be this specific user
})
```

### OR Logic with `requireAll`

You can change the behavior to require **any one** permission (OR condition) by setting the `requireAll` parameter to `false`:

```lua
-- Server-side: Player needs ANY of these permissions
RBXPerms(player, {
    "Group:123456:>=100",  -- Has high rank in group
    "Badge:987654",         -- OR has this badge
    "UserId:111111"         -- OR is this specific user
}, false)  -- requireAll = false enables OR logic

-- Client-side: Local player needs ANY of these permissions
RBXPerms({
    "Badge:123456",
    "Badge:789012"
}, false)
```

**Examples:**

```lua
-- Allow VIPs: Premium members OR group admins
RBXPerms(player, {
    "Premium",
    "Group:123456:>=250"
}, false)

-- Allow access: Specific users OR badge holders
RBXPerms(player, {
    "UserId:111111,222222,333333",
    "Badge:987654"
}, false)

-- Complex: Must be in group AND (has badge OR is premium)
local inGroup = RBXPerms(player, { "Group:123456" })
local hasExtra = RBXPerms(player, { "Badge:123", "Premium" }, false)
if inGroup and hasExtra then
    -- Grant access
end
```

## Creating Custom Permissions

You can extend RBXPerms by creating your own permission types. Here's how:

### Step 1: Create a New Module

Create a new ModuleScript in the `RBXPerms/Permissions` folder. The name of the module is the permission type name.

For example, create `Premium.luau`:

```lua
--[[
    Premium Permission Type
    Checks if a player has Roblox Premium membership
]]

return function(player: Player, args: { string }): boolean
    -- The function receives the player and an array of arguments
    -- Return true if the player meets the permission, false otherwise
    
    return player.MembershipType == Enum.MembershipType.Premium
end
```

### Step 2: Use Your Custom Permission

```lua
RBXPerms(player, {
    "Premium"  -- Your custom permission type
})
```

### Custom Permission Examples

#### GamePass Permission
```lua
-- GamePass.luau
local MarketplaceService = game:GetService("MarketplaceService")

return function(player: Player, args: { string }): boolean
    local gamePassId = tonumber(args[1] or "")
    assert(type(gamePassId) == "number", "Invalid GamePass ID")
    
    local success, hasPass = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
    end)
    
    if not success then
        warn("Failed to check gamepass for player " .. player.Name)
        return false
    end
    
    return hasPass
end
```

Usage:
```lua
RBXPerms(player, {
    "GamePass:123456"
})
```

#### Friends Permission
```lua
-- Friends.luau
return function(player: Player, args: { string }): boolean
    local targetUserId = tonumber(args[1] or "")
    assert(type(targetUserId) == "number", "Invalid UserId")
    
    local success, isFriend = pcall(function()
        return player:IsFriendsWith(targetUserId)
    end)
    
    if not success then
        warn("Failed to check friendship for player " .. player.Name)
        return false
    end
    
    return isFriend
end
```

Usage:
```lua
RBXPerms(player, {
    "Friends:987654"  -- Must be friends with UserId 987654
})
```

#### TeamCheck Permission
```lua
-- TeamCheck.luau
return function(player: Player, args: { string }): boolean
    local teamName = args[1]
    assert(type(teamName) == "string", "Invalid team name")
    
    if not player.Team then
        return false
    end
    
    return player.Team.Name == teamName
end
```

Usage:
```lua
RBXPerms(player, {
    "TeamCheck:Red Team"
})
```

### Custom Permission Guidelines

When creating custom permissions:

1. **Module Name**: Name matches the permission type string
2. **Return Function**: Must return a function with signature `(player: Player, args: { string }): boolean`
3. **Arguments**: Receive arguments as a string array from the permission string
4. **Validation**: Validate arguments and assert on invalid input
5. **Error Handling**: Use pcall for API calls that might fail
6. **Return Value**: Return `true` if permission is met, `false` otherwise

## API Reference

### RBXPerms(player, permissions, requireAll?)
Evaluates permissions for a specific player (server or client).

**Parameters:**
- `player` (Player): The player to check permissions for
- `permissions` (table): Array of permission strings
- `requireAll` (boolean, optional): If `true` (default), ALL permissions must be met (AND logic). If `false`, ANY permission can be met (OR logic)

**Returns:**
- `boolean`: `true` if permissions are satisfied based on `requireAll` setting, `false` otherwise

**Examples:**
```lua
-- AND logic (default): Must have ALL permissions
RBXPerms(player, { "Group:123", "Badge:456" })  -- true required
RBXPerms(player, { "Group:123", "Badge:456" }, true)  -- Explicit AND

-- OR logic: Must have ANY permission
RBXPerms(player, { "Group:123", "Badge:456" }, false)
```

### RBXPerms(permissions, requireAll?)
Evaluates permissions for the local player (client-only).

**Parameters:**
- `permissions` (table): Array of permission strings
- `requireAll` (boolean, optional): If `true` (default), ALL permissions must be met (AND logic). If `false`, ANY permission can be met (OR logic)

**Returns:**
- `boolean`: `true` if permissions are satisfied based on `requireAll` setting, `false` otherwise

**Examples:**
```lua
-- AND logic (default): Must have ALL permissions
RBXPerms({ "Badge:123", "Badge:456" })

-- OR logic: Must have ANY permission
RBXPerms({ "Badge:123", "Badge:456" }, false)
```

## License

MIT License - © 2025 Meta Games LLC. All rights reserved.

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests on [GitHub](https://github.com/Metatable-Games/RBXPerms).
