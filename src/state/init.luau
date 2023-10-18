local RunService = game:GetService("RunService")

local rts = require(script.Parent.rts)
local vide = require(script.Parent.Parent.vide)

local source = vide.source

return vide.root(function()
	local cts = require(script.cts)

	return {

		cts = cts,
		worlds = source({} :: { { world: rts.Registry, name: string } }),
		schedulers = source({} :: { rts.Scheduler }),

		current_client_world = source({} :: { world: rts.Registry, name: string }),
		enabled = source(false),

		can_use_debugger = function(player: Player)
			return game.CreatorType == Enum.CreatorType.User
					and player.UserId == game.CreatorId
				or RunService:IsStudio()
		end,
	}
end)
