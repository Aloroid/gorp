local Players = game:GetService("Players")

local active_connectors = require(script.Parent.Parent.active_connectors)
local gorp = require(script.Parent.Parent.Parent.gorp)
local queue = require(script.Parent.Parent.Parent.modules.queue)

local player_removing = queue(Players.PlayerRemoving)

return function()
	for player in player_removing:iter() do
		for _, t in active_connectors :: { [string]: { [gorp.connector]: true } } do
			for connector in t do
				if connector.player ~= player then continue end
				t[connector] = nil
			end
		end
	end
end
