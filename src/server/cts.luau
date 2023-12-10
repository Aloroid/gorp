--[[

	Internal components

]]

local ecr7 = require(script.Parent.Parent.modules.ecr7)
local rts = require(script.Parent.Parent.rts)

local counter = 0
local function increment_counter()
	counter += 1
	return counter
end

return ecr7.name({

	-- the name of a scheduler / registry
	Name = ecr7.component() :: string,
	Components = ecr7.component() :: { [number]: string },

	Scheduler = ecr7.component() :: { ecr7.entity }, -- contain systems
	Registry = ecr7.component() :: rts.Registry,

	-- the connector who requested for the given data
	Requester = ecr7.component() :: rts.connector,
	SelectedRegistry = ecr7.component() :: ecr7.entity,
	Query = ecr7.component() :: string,

	System = ecr7.component() :: rts.System,
	Average = ecr7.component() :: rts.RollingAverage,
	Queries = ecr7.component() :: { ecr7.entity },
	QueryData = ecr7.component() :: rts.QueryData,
	Paused = ecr7.tag(),

	-- the connector who is connected to this server
	Receiver = ecr7.component() :: rts.connector,
})
