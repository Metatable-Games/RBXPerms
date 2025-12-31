--[[
	© 2025 Meta Games LLC. All rights reserved.
	License: MIT
	GitHub: https://github.com/Metatable-Games/RBXPerms
]]

return function (player: Player, args: { string }): boolean
    -- > Extract user ID
    local userIds = {}

    for userIdStr in string.gmatch(args[1], "([^,]+)") do
        local userId = tonumber(userIdStr)
        assert(userId, "Invalid UserId in permission string.")
        table.insert(userIds, userId)
    end

    -- > Check if player's UserId is in the list
    return table.find(userIds, player.UserId) ~= nil
end

-- > Example 1: "UserId:123456" checks if the player's UserId is 123456
-- > Example 2: "!UserId:123" checks if the player's UserId is NOT 123
-- > Example 3: "UserId:123456,789012" checks if the player's UserId is either 123456 or 789012