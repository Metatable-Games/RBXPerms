--[[
	© 2025 Meta Games LLC. All rights reserved.
	License: MIT
	GitHub: https://github.com/Metatable-Games/RBXPerms
]]

return function(player: Player, args: { string }): boolean
	-- > Extract group ID
	local groupId = tonumber(args[1] or "")
	assert(type(groupId) == "number", "Invalid Group ID in permission string.")

	-- > Get player's rank in the group
	local success, rank = pcall(function()
		return player:GetRankInGroupAsync(groupId)
	end)

	if not success then
		warn("Failed to get rank for player " .. player.Name .. " in group " .. tostring(groupId))
		return false
	end

	-- > If no rank argument is provided, just check for membership
	if #args == 1 then
		return rank > 0
	end

	-- > Parse rank condition
	local rankCondition = args[2]
	local operator, value1, value2
	if string.find(rankCondition, "-") then
		operator = "range"
		local rangeParts = {}
		for part in string.gmatch(rankCondition, "([^%-]+)") do
			table.insert(rangeParts, tonumber(part))
		end
		value1 = rangeParts[1]
		value2 = rangeParts[2]
	elseif string.sub(rankCondition, 1, 2) == "<=" then
		operator = "<="
		value1 = tonumber(string.sub(rankCondition, 3))
	elseif string.sub(rankCondition, 1, 2) == ">=" then
		operator = ">="
		value1 = tonumber(string.sub(rankCondition, 3))
	elseif string.sub(rankCondition, 1, 1) == "<" then
		operator = "<"
		value1 = tonumber(string.sub(rankCondition, 2))
	elseif string.sub(rankCondition, 1, 1) == ">" then
		operator = ">"
		value1 = tonumber(string.sub(rankCondition, 2))
	else
		operator = "=="
		value1 = tonumber(rankCondition)
	end

	-- > Evaluate rank condition
	if operator == "range" then
		return rank >= value1 and rank <= value2
	elseif operator == "<=" then
		return rank <= value1
	elseif operator == ">=" then
		return rank >= value1
	elseif operator == "<" then
		return rank < value1
	elseif operator == ">" then
		return rank > value1
	elseif operator == "==" then
		return rank == value1
	end

	-- > Fallback (should not reach here)
	return false
end

-- > Example 1: "Group:123456" checks if the player's is in group 123456
-- > Example 2: "!Group:123456" checks if the player's is NOT in group 123456
-- > Example 3: "Group:123456:1-2" checks if the player's rank in group 123456 is between 1 and 2 inclusive
-- > Example 4: "Group:123456:<5" checks if the player's rank in group 123456 is less than 5
-- > Example 5: "Group:123456:<=5" checks if the player's rank in group 123456 is less than or equal to 5
-- > Example 6: "Group:123456:>5" checks if the player's rank in group 123456 is greater than 5
-- > Example 7: "Group:123456:>=5" checks if the player's rank in group 123456 is greater than or equal to 5
-- > Example 8: "Group:123456:5" checks if the player's rank in group 123456 is exactly 5
