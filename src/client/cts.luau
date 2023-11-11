--[[

	Internal components

]]

local ecr = require(script.Parent.Parent.Parent.ecr)
local rts = require(script.Parent.Parent.rts)

return ecr.name({

	-- this is all server components
	-- the name of a scheduler / registry
	Name = ecr.component() :: string,
	Components = ecr.component() :: { [number]: string },

	Scheduler = ecr.tag(), -- contain systems
	Registry = ecr.tag(),

	Systems = ecr.component() :: { number },

	Requester = ecr.component() :: Player,
	SelectedRegistry = ecr.component() :: ecr.Entity,
	Query = ecr.component() :: string,

	System = ecr.component() :: rts.System,
	Average = ecr.component() :: rts.RollingAverage,
	Queries = ecr.component() :: { ecr.Entity },
	QueryData = ecr.component() :: rts.QueryData,
	Paused = ecr.tag(),

	-- this is all client components
	-- the id of the actor
	ActorId = ecr.component() :: number,
	-- if it's replicated from either the server or the client.
	ReplicatedFrom = ecr.component() :: "server" | "client",
	-- the id of the entity on that server
	ServerId = ecr.component() :: number,

	--context
	ServerComponents = ecr.component() :: { [number]: any },
})
