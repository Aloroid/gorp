--[[

	the client object should only be created once on the client.

]]

local RunService = game:GetService("RunService")

local add_local_server = require(script.add_local_server)
local events = require(script.Parent.events)
local new_scheduler = require(script.Parent.server.scheduler)
local replicate_components = require(script.systems.replicate_components)
local replicate_core = require(script.systems.replicate_core)
local stop_multi_require = require(script.Parent.modules.stop_multi_require)

stop_multi_require()

events.request_servers:Fire(true)

-- create all the connections necessary
events.new_server.Event:Connect(add_local_server)

local scheduler = new_scheduler("gorpclient")
RunService.Heartbeat:Connect(function()
	scheduler:system("replicate_core", replicate_core)
	scheduler:system("replicate_components", replicate_components)
	scheduler:finish()
end)

return {}
