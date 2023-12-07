local cts = require(script.Parent.Parent.cts)
local ecr = require(script.Parent.Parent.Parent.Parent.ecr)
local events = require(script.Parent.Parent.Parent.events)
local registry = require(script.Parent.Parent.registry)
local servers = require(script.Parent.Parent.servers)

local updated = ecr.queue(events.replicate_components)

local function replicate_components()
	for connector, components in updated:iter() do
		local context = servers[if connector.player then "client" else "server"][connector.from]
		local ctypes = {}

		-- i have to tonumber this because reasons
		for key, name in components do
			ctypes[tonumber(key) :: number] = name
		end

		print("set components of", connector.from, "to", ctypes)

		registry:set(context, cts.Components, ctypes)
	end
end

return replicate_components
