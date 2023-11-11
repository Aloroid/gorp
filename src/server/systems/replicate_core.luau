local common_actor_id = require(script.Parent.Parent.Parent.common_actor_id)
local cts = require(script.Parent.Parent.cts)
local events = require(script.Parent.Parent.Parent.events)
local registry = require(script.Parent.Parent.registry)

local scheduler_changed = registry:track(cts.Name, cts.Scheduler)
local registry_changed = registry:track(cts.Name, cts.Registry)

local function replicate_core()
	local changed = false

	for _ in scheduler_changed do
		changed = true
	end

	for _ in registry_changed do
		changed = true
	end

	if not changed then return end

	local registries = {}
	local schedulers = {}

	for id, name in registry:view(cts.Name, cts.Registry) do
		table.insert(registries, { name = name, id = id })
	end

	for id, name in registry:view(cts.Name, cts.Scheduler) do
		table.insert(schedulers, { name = name, id = id })
	end

	events.replicate_core_data:Fire(common_actor_id, registries, schedulers)
end

return replicate_core
