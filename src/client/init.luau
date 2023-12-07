--[[

	the client object should only be created once on the client.

]]

local RunService = game:GetService("RunService")

local add_server = require(script.add_server)
local events = require(script.Parent.events)
local new_scheduler = require(script.Parent.server.scheduler)
local replicate_components = require(script.systems.replicate_components)
local replicate_core = require(script.systems.replicate_core)
local stop_multi_require = require(script.Parent.modules.stop_multi_require)

stop_multi_require()

-- create all the connections necessary
events.replicate_core_data:connect(function(connector)
	-- adds the server
	add_server(connector.from :: number, connector.namespace)
end)

local scheduler = new_scheduler("gorpclient")
RunService.Heartbeat:Connect(function()
	scheduler:system("replicate_core", replicate_core)
	scheduler:system("replicate_components", replicate_components)
	scheduler:finish()
end)

task.defer(function()
	print("uwr")
	events.request_servers:fire({
		namespace = "client",
	})

	events.request_servers:fire({
		namespace = "server",
	})
end)

return {}
