--[[

	Binds all things to the remotes

]]

local remotes = require(script.Parent.remotes)
local scheduler = require(script.scheduler)

remotes.subscribe_scheduler_data.OnServerInvoke =
	scheduler.subscribe_scheduler_data
remotes.unsubscribe_scheduler_data.OnServerInvoke =
	scheduler.unsubscribe_scheduler_data
remotes.get_server_schedulers.OnServerInvoke = scheduler.get_schedulers

return {

	scheduler = scheduler,
}
