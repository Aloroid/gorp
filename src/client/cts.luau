--[[

	Internal components

]]

local ecr7 = require(script.Parent.Parent.modules.ecr7)
local rts = require(script.Parent.Parent.rts)

return ecr7.name({

	-- this is all server components
	-- the name of a scheduler / registry
	Name = ecr7.component() :: string,
	Components = ecr7.component() :: { [number]: string },

	Scheduler = ecr7.tag(), -- contain systems
	Registry = ecr7.tag(),

	Systems = ecr7.component() :: { number },

	Requester = ecr7.component() :: Player,
	SelectedRegistry = ecr7.component() :: ecr7.entity,
	Query = ecr7.component() :: string,

	System = ecr7.component() :: rts.System,
	Average = ecr7.component() :: rts.RollingAverage,
	Queries = ecr7.component() :: { ecr7.entity },
	QueryData = ecr7.component() :: rts.QueryData,
	Paused = ecr7.tag(),

	-- this is all client components
	-- the id of the actor
	ActorId = ecr7.component() :: number,
	-- if it's replicated from either the server or the client.
	ReplicatedFrom = ecr7.component() :: "server" | "client",
	-- the id of the entity on that server
	ServerId = ecr7.component() :: number,

	-- context
	ServerComponents = ecr7.component() :: { [number]: any },
})
