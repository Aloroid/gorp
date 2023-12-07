--[[

	this system replicates the registry and scheduler to new connectors.
	it will also create the 

]]

local cts = require(script.Parent.Parent.cts)
local ecr7 = require(script.Parent.Parent.Parent.modules.ecr7)
local events = require(script.Parent.Parent.Parent.events)
local registry = require(script.Parent.Parent.registry)
local reverse_connector = require(script.Parent.Parent.reverse_connector)

local scheduler_changed = registry:track(cts.Name, cts.Scheduler)
local registry_changed = registry:track(cts.Name, cts.Registry)
local request_server = ecr7.queue(events.request_servers)

local function replicate_core()
	local changed = false

	for _ in scheduler_changed do
		changed = true
	end

	for _ in registry_changed do
		changed = true
	end

	local registries = {}
	local schedulers = {}

	for id, name in registry:view(cts.Name, cts.Registry) do
		table.insert(registries, { name = name, id = id })
	end

	for id, name in registry:view(cts.Name, cts.Scheduler) do
		table.insert(schedulers, { name = name, id = id })
	end

	-- replicate to new connectors (if any)
	for connector in request_server:iter() do
		print("sending initial data to", connector)
		events.replicate_core_data:fire(reverse_connector(connector), registries, schedulers)
	end

	if not changed then return end

	-- replicate to other connectors
	for _, connector in registry:view(cts.Receiver) do
		events.replicate_core_data:fire(connector, registries, schedulers)
	end
end

return replicate_core
