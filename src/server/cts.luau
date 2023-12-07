--[[

	Internal components

]]

local ecr7 = require(script.Parent.Parent.modules.ecr7)
local rts = require(script.Parent.Parent.rts)

return ecr7.name({

	-- the name of a scheduler / registry
	Name = ecr7.component() :: string,
	Components = ecr7.component() :: { [number]: string },

	Scheduler = ecr7.component() :: { ecr7.entity }, -- contain systems
	Registry = ecr7.component() :: rts.Registry,

	Requester = ecr7.component() :: Player,
	SelectedRegistry = ecr7.component() :: ecr7.entity,
	Query = ecr7.component() :: string,

	System = ecr7.component() :: rts.System,
	Average = ecr7.component() :: rts.RollingAverage,
	Queries = ecr7.component() :: { ecr7.entity },
	QueryData = ecr7.component() :: rts.QueryData,
	Paused = ecr7.tag(),

	Receiver = ecr7.component() :: rts.connector,
})
