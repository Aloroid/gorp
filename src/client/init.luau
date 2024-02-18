--[[

	the client object should only be created once on the client.

]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local stop_multi_require = require(script.Parent.modules.stop_multi_require)
local traffic_check = require(script.Parent.modules.traffic_check)

stop_multi_require("cannot get client twice")

local enabled = require(script.enabled)
local gorp_selector = require(script.widgets.gorp_selector)
local message_new_servers = require(script.systems.message_new_servers)
local new_scheduler = require(script.Parent.server.scheduler)
local remotes = require(script.Parent.remotes)

local replicate_components = require(script.systems.replicate_components)
local replicate_core = require(script.systems.replicate_core)

local scheduler = new_scheduler("gorpclient")
RunService.Heartbeat:Connect(function()
	scheduler:system("replicate_core", replicate_core)
	scheduler:system("replicate_components", replicate_components)
	scheduler:system("message_new_systems", message_new_servers)
	scheduler:finish()
end)

--print("requested for servers")
task.spawn(function()
	while traffic_check.is_player_permitted(Players.LocalPlayer) == false do
		task.wait(5)
	end

	remotes.request_servers:fire({
		namespace = "client",
	})

	remotes.request_servers:fire({
		namespace = "server",
	})
end)

return {

	enabled = enabled,
	gorp_selector = gorp_selector,
}
