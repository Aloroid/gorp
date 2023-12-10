--[[

	This module provides a helper function to block traffic from unauthorized
	players and gives the developre a signal so they can choose how to handle
	the player when they perform something unauthorized

]]

local RunService = game:GetService("RunService")

local signal = require(script.Parent.signal)

local check_function = function(player: Player)
	return player.UserId == game.CreatorId and game.CreatorType == Enum.CreatorType.User or RunService:IsStudio()
end

local function is_player_permitted(player: Player) return check_function(player) end

local player_blocked, fire = signal()

local function check_player(player: Player?)
	if not player then return true end

	if is_player_permitted(player) then
		return true
	else
		fire(player)
		return false
	end
end

local function overwrite_check_function(new_callback: (player: Player) -> boolean) check_function = new_callback end

return {

	player_blocked = player_blocked,

	check_player = check_player,
	is_player_permitted = is_player_permitted,

	overwrite_check_function = overwrite_check_function,
}
