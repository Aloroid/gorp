--[[

	Binds all things to the remotes

]]

local registry = require(script.registry)
local remotes = require(script.Parent.remotes)
local scheduler = require(script.scheduler)

remotes.subscribe_scheduler_data.OnServerInvoke =
	scheduler.subscribe_scheduler_data
remotes.unsubscribe_scheduler_data.OnServerInvoke =
	scheduler.unsubscribe_scheduler_data
remotes.get_server_schedulers.OnServerInvoke = scheduler.get_schedulers

remotes.get_server_registries.OnServerInvoke = registry.get_server_registries
remotes.set_query.OnServerInvoke = registry.set_query

return {

	scheduler = scheduler,
}