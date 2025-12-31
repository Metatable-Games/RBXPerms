--[[
	© 2025 Meta Games LLC. All rights reserved.
	License: MIT
	GitHub: https://github.com/Metatable-Games/RBXPerms
]]

local BadgeService = game:GetService("BadgeService")

return function(player: Player, args: { string }): boolean
	-- > Extract badge ID
	local badgeId = tonumber(args[1] or "")
	assert(type(badgeId) == "number", "Invalid Badge ID in permission string.")

	-- > Check if the player has the badge
	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	end)

    if not success then
        warn("Failed to get badge status for player " .. player.Name .. " for badge " .. tostring(badgeId))
        return false
    end

    return hasBadge
end
