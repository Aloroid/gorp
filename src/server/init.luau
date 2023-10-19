--[[

	Binds all things to the remotes

]]

local cts = require(script.cts)
local registry = require(script.registry)
local remotes = require(script.Parent.remotes)
local scheduler = require(script.scheduler)
local system = require(script.system)

remotes.subscribe_scheduler_data.OnServerInvoke =
	scheduler.subscribe_scheduler_data
remotes.unsubscribe_scheduler_data.OnServerInvoke =
	scheduler.unsubscribe_scheduler_data
remotes.get_server_schedulers.OnServerInvoke = scheduler.get_schedulers

remotes.get_server_registries.OnServerInvoke = registry.get_server_registries
remotes.set_query.OnServerInvoke = registry.set_query

remotes.get_server_cts.OnServerInvoke = cts.get_server_cts

remotes.get_system_performance_data.OnServerInvoke =
	system.get_system_performance_data
remotes.stop_flow_system_performance_data.OnServerEvent:Connect(
	system.disconnect
)

return {

	registry = registry,
	scheduler = scheduler,
	cts = cts.get_server_cts,
}
