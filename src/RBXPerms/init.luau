--[[
	© 2025 Meta Games LLC. All rights reserved.
	License: MIT
	GitHub: https://github.com/Metatable-Games/RBXPerms
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RBXPerms = {}

--[[
    Evaluates whether a player has the specified permissions.

    @param player Player - The player whose permissions are to be evaluated.
    @param permissions { string } - A table of permission strings to check against the player's permissions.
    @param requireAll boolean? - If true, the player must have all specified permissions. If false, having any one permission is sufficient. Defaults to true.
    @return boolean - Returns true if the player has all specified permissions, false otherwise.
]]
function RBXPerms:evaulatePermissions(player: Player, permissions: { string }, requireAll: boolean?): boolean
	assert(typeof(player) == "Instance" and player:IsA("Player"), "First argument must be a Player instance.")
	assert(type(permissions) == "table", "Second argument must be a table of permission strings.")
    assert(type(requireAll) == "boolean" or requireAll == nil, "Third argument must be a boolean or nil.")

    if requireAll == nil then
        requireAll = true
    end

	for _, permission in ipairs(permissions) do
		assert(type(permission) == "string", "Permission values must be strings.")

		local isNegated = string.sub(permission, 1, 1) == "!"
		local permString = isNegated and string.sub(permission, 2) or permission

		-- > Extract Permission Name/Type and it's arguments
		local separatorIndex = string.find(permString, ":")
		local permType = ""
		local permArgs = {}

		if separatorIndex then
			permType = string.sub(permString, 1, separatorIndex - 1)
			local argsString = string.sub(permString, separatorIndex + 1)
			for arg in string.gmatch(argsString, "([^:]+)") do
				table.insert(permArgs, arg)
			end
		else
			permType = permString
		end

		-- > Load the corresponding permission module
		local success, permModule = pcall(function()
			return require(script.Permissions:FindFirstChild(permType))
		end)

		assert(success and type(permModule) == "function", "Invalid permission type: " .. permType)

		-- > Evaluate the permission
		local hasPermission = permModule(player, permArgs)

		-- > Apply negation if necessary
		if isNegated then
			hasPermission = not hasPermission
		end

		-- > If any permission check fails, return false
		if not hasPermission and requireAll then
			return false
		end
	end

	return true
end

--[[
    Main function to evaluate permissions.

    Usage:
    1. RBXPerms(permissionsTable, requireAll) - Evaluates permissions for the local player.
    2. RBXPerms(player, permissionsTable, requireAll) - Evaluates permissions for the specified player.

    @param ... - Variable arguments based on usage.
    @return boolean - Result of permission evaluation.
]]
return function(...)
	local args = { ... }
    assert(#args == 1 or #args == 2, "Expected 1 or 2 arguments, got " .. tostring(#args))

    if #args == 1 then
		-- > If only one argument is provided, assume it's the permissions table and use the local player.
		assert(RunService:IsClient(), "Local player can only be used in a client context.")
		return RBXPerms:evaulatePermissions(Players.LocalPlayer, ...)
	else
		-- > If two arguments are provided, use them as player and permissions table.
		return RBXPerms:evaulatePermissions(...)
	end
end
