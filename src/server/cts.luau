--[[

	Internal components

]]

local ecr = require(script.Parent.Parent.Parent.ecr)
local rts = require(script.Parent.Parent.rts)

return ecr.name({

	-- the name of a scheduler / registry
	Name = ecr.component() :: string,
	Components = ecr.component() :: { [number]: string },

	Scheduler = ecr.component() :: { ecr.Entity }, -- contain systems
	Registry = ecr.component() :: ecr.Registry,

	Requester = ecr.component() :: Player,
	SelectedRegistry = ecr.component() :: ecr.Entity,
	Query = ecr.component() :: string,

	System = ecr.component() :: rts.System,
	Average = ecr.component() :: rts.RollingAverage,
	Queries = ecr.component() :: { ecr.Entity },
	QueryData = ecr.component() :: rts.QueryData,
	Paused = ecr.tag(),
})
