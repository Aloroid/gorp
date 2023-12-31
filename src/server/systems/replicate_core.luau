local active_connectors = require(script.Parent.Parent.active_connectors)
local events = require(script.Parent.Parent.events)
local queue = require(script.Parent.Parent.Parent.modules.queue)
local remotes = require(script.Parent.Parent.Parent.remotes)
local reverse_connector = require(script.Parent.Parent.Parent.modules.reverse_connector)
local server_state = require(script.Parent.Parent.server_state)

local requesting_server_data = queue(remotes.request_servers)
local scheduler_created = queue(events.scheduler_created)
local world_added = queue(events.world_created)

return function()
	local changed = false

	for _ in scheduler_created do
		changed = true
	end

	for _ in world_added do
		changed = true
	end

	local registries = {}
	local schedulers = {}

	for id, entry in server_state.registries do
		table.insert(registries, { name = entry.name, id = id })
	end

	for id, entry in server_state.schedulers do
		table.insert(schedulers, { name = entry.name, id = id })
	end

	-- replicate to new connectors (if any)
	for connector in requesting_server_data:iter() do
		--print("received request")
		local reverse = reverse_connector(connector)
		remotes.replicate_core_data:fire(reverse, registries, schedulers)
		active_connectors.connected[reverse] = true
	end

	if not changed then return end

	-- replicate to other connectors
	for connector in active_connectors.connected do
		remotes.replicate_core_data:fire(connector, registries, schedulers)
	end
end
