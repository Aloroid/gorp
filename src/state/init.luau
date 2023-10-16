local RunService = game:GetService("RunService")

local rts = require(script.Parent.rts)
local vide = require(script.Parent.Parent.vide)

local source = vide.source

return vide.root(function()
	local cts = require(script.cts)

	return {

		cts = cts,
		worlds = source({} :: { { world: rts.Registry, name: string } }),

		can_use_debugger = function(player: Player)
			return RunService:IsStudio()
		end,

		current_client_world = source({} :: { world: rts.Registry, name: string }),
	}
end)
