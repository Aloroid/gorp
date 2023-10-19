local Players = game:GetService("Players")

local remotes = require(script.Parent.Parent.remotes)
local state = require(script.Parent.Parent.state)
local vide = require(script.Parent.Parent.Parent.vide)

local players = {}

local function get_server_cts(player: Player)
	if not state.can_use_debugger(player) then return {} end
	players[player] = true

	return state.cts.keys()
end

vide.root(function()
	vide.effect(function()
		local new = state.cts.keys()

		for player in players do
			remotes.update_server_cts:FireClient(player, new)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player) players[player] = nil end)

return {
	get_server_cts = get_server_cts,
}
